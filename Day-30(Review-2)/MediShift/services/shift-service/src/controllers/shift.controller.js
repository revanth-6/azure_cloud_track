const axios = require('axios');
const Shift = require('../models/shift.model');
const { Op } = require('sequelize');

const STAFF_SERVICE_URL = process.env.STAFF_SERVICE_URL || 'http://localhost:3002';
const LEAVE_SERVICE_URL = process.env.LEAVE_SERVICE_URL || 'http://localhost:3004';

const timeRegex = /^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/;

const getShiftType = (startTime) => {
  const hour = parseInt(startTime.split(':')[0], 10);
  if (hour >= 5 && hour < 12) return 'morning';
  if (hour >= 12 && hour < 18) return 'afternoon';
  return 'night';
};

const toMins = (t) => {
  const [h, m] = t.split(':').map(Number);
  return h * 60 + m;
};

// GET /api/shifts
exports.getAll = async (req, res) => {
  try {
    const shifts = await Shift.findAll({ order: [['shift_date', 'DESC']] });
    return res.status(200).json({ success: true, data: shifts });
  } catch (error) {
    console.error(`[${new Date().toISOString()}] Get shifts error: ${error.message}`);
    if (error.name === 'SequelizeConnectionError') return res.status(503).json({ success: false, message: 'Database unavailable' });
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

// GET /api/shifts/check-dates (internal)
exports.checkDates = async (req, res) => {
  try {
    const { staffId, fromDate, toDate } = req.query;
    if (!staffId || !fromDate || !toDate) return res.status(400).json({ success: false, message: 'staffId, fromDate, and toDate are required' });
    const conflicts = await Shift.findAll({ where: { staff_id: staffId, shift_date: { [Op.between]: [fromDate, toDate] } } });
    return res.status(200).json({ success: true, data: { hasConflicts: conflicts.length > 0, conflicts } });
  } catch (error) {
    console.error(`[${new Date().toISOString()}] Check dates error: ${error.message}`);
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

// PUT /api/shifts/cancel-by-leave (internal)
exports.cancelByLeave = async (req, res) => {
  try {
    const { staffId, fromDate, toDate } = req.body;
    if (!staffId || !fromDate || !toDate) return res.status(400).json({ success: false, message: 'staffId, fromDate, and toDate are required' });
    const result = await Shift.destroy({ where: { staff_id: staffId, shift_date: { [Op.between]: [fromDate, toDate] } } });
    console.log(`[${new Date().toISOString()}] Cancelled ${result} shifts for staff ${staffId} (${fromDate} to ${toDate})`);
    return res.status(200).json({ success: true, data: { cancelledCount: result } });
  } catch (error) {
    console.error(`[${new Date().toISOString()}] Cancel shifts error: ${error.message}`);
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

// GET /api/shifts/my-shifts
exports.getMyShifts = async (req, res) => {
  try {
    const staff_id = req.user.staff_id;
    if (!staff_id) return res.status(400).json({ success: false, message: 'No staff profile linked' });
    const shifts = await Shift.findAll({ where: { staff_id }, order: [['shift_date', 'DESC']] });
    return res.status(200).json({ success: true, data: shifts });
  } catch (error) {
    console.error(`[${new Date().toISOString()}] Get my shifts error: ${error.message}`);
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

// GET /api/shifts/staff/:staffId
exports.getByStaffId = async (req, res) => {
  try {
    const shifts = await Shift.findAll({ where: { staff_id: req.params.staffId }, order: [['shift_date', 'DESC']] });
    return res.status(200).json({ success: true, data: shifts });
  } catch (error) {
    console.error(`[${new Date().toISOString()}] Get shifts by staff error: ${error.message}`);
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

// POST /api/shifts
exports.create = async (req, res) => {
  try {
    const { staff_id, shift_date, start_time, end_time } = req.body;
    if (!staff_id) return res.status(400).json({ success: false, message: 'Staff member is required' });
    if (!shift_date) return res.status(400).json({ success: false, message: 'Shift date is required' });
    if (!start_time) return res.status(400).json({ success: false, message: 'Start time is required' });
    if (!end_time) return res.status(400).json({ success: false, message: 'End time is required' });

    const parsedDate = new Date(shift_date + 'T00:00:00');
    if (isNaN(parsedDate.getTime())) return res.status(400).json({ success: false, message: 'Invalid date format. Use YYYY-MM-DD' });

    const today = new Date(); today.setHours(0, 0, 0, 0);
    if (parsedDate < today) return res.status(400).json({ success: false, message: 'Cannot create shift for a past date' });

    const st = start_time.substring(0, 5);
    const et = end_time.substring(0, 5);
    if (!timeRegex.test(st)) return res.status(400).json({ success: false, message: 'Invalid start time format. Use HH:MM' });
    if (!timeRegex.test(et)) return res.status(400).json({ success: false, message: 'Invalid end time format. Use HH:MM' });

    const shift_type = getShiftType(st);

    let duration = toMins(et) - toMins(st);
    if (duration < 0) duration += 24 * 60;
    if (shift_type !== 'night' && toMins(et) <= toMins(st)) return res.status(400).json({ success: false, message: 'End time must be after start time' });
    if (duration < 60) return res.status(400).json({ success: false, message: 'Shift must be at least 1 hour long' });
    if (duration > 720) return res.status(400).json({ success: false, message: 'Shift cannot be longer than 12 hours' });

    // Verify staff exists
    try {
      await axios.get(`${STAFF_SERVICE_URL}/api/staff/${staff_id}`, { headers: { Authorization: req.headers.authorization }, timeout: 5000 });
    } catch (error) {
      if (error.response && error.response.status === 404) return res.status(404).json({ success: false, message: 'Staff member not found' });
      return res.status(503).json({ success: false, message: 'Unable to verify staff. Please try again.' });
    }

    // Check duplicate shift on same date
    const existingShift = await Shift.findOne({ where: { staff_id, shift_date } });
    if (existingShift) return res.status(409).json({ success: false, message: 'Staff already has a shift assigned on this date' });

    // Check approved leave
    try {
      const leaveResponse = await axios.get(
        `${LEAVE_SERVICE_URL}/api/leaves/check-approved`,
        { params: { staffId: staff_id, date: shift_date }, timeout: 5000 }
      );
      if (leaveResponse.data && leaveResponse.data.success && leaveResponse.data.data && leaveResponse.data.data.hasApprovedLeave === true) {
        return res.status(400).json({ success: false, message: 'Cannot assign shift. Staff has approved leave on this date.' });
      }
    } catch (leaveError) {
      console.error(`[${new Date().toISOString()}] Leave check error: ${leaveError.message}`);
      return res.status(503).json({ success: false, message: 'Unable to verify leave status. Please try again.' });
    }

    const shift = await Shift.create({ staff_id, shift_date, start_time, end_time, shift_type });
    console.log(`[${new Date().toISOString()}] Shift created for staff ${staff_id} on ${shift_date} (${shift_type})`);
    return res.status(201).json({ success: true, data: shift });
  } catch (error) {
    console.error(`[${new Date().toISOString()}] Create shift error: ${error.message}`);
    if (error.name === 'SequelizeUniqueConstraintError') return res.status(409).json({ success: false, message: 'Duplicate shift' });
    if (error.name === 'SequelizeConnectionError') return res.status(503).json({ success: false, message: 'Database unavailable' });
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

// PUT /api/shifts/:id
exports.update = async (req, res) => {
  try {
    const shift = await Shift.findByPk(req.params.id);
    if (!shift) return res.status(404).json({ success: false, message: 'Shift not found' });

    const { staff_id, shift_date, start_time, end_time } = req.body;
    if (staff_id) shift.staff_id = staff_id;
    if (shift_date) shift.shift_date = shift_date;
    if (start_time) { shift.start_time = start_time; shift.shift_type = getShiftType(start_time.substring(0, 5)); }
    if (end_time) shift.end_time = end_time;

    await shift.save();
    console.log(`[${new Date().toISOString()}] Shift updated: ${req.params.id}`);
    return res.status(200).json({ success: true, data: shift });
  } catch (error) {
    console.error(`[${new Date().toISOString()}] Update shift error: ${error.message}`);
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

// DELETE /api/shifts/:id
exports.remove = async (req, res) => {
  try {
    const shift = await Shift.findByPk(req.params.id);
    if (!shift) return res.status(404).json({ success: false, message: 'Shift not found' });
    await shift.destroy();
    console.log(`[${new Date().toISOString()}] Shift deleted: ${req.params.id}`);
    return res.status(200).json({ success: true, data: { message: 'Shift deleted successfully' } });
  } catch (error) {
    console.error(`[${new Date().toISOString()}] Delete shift error: ${error.message}`);
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
};
