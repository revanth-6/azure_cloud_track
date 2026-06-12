const axios = require('axios');
const Leave = require('../models/leave.model');
const { Op } = require('sequelize');

const SHIFT_SERVICE_URL = process.env.SHIFT_SERVICE_URL || 'http://localhost:3003';

// GET /api/leaves/check-approved (internal — no auth)
exports.checkApprovedLeave = async (req, res) => {
  try {
    const { staffId, date } = req.query;
    if (!staffId || !date) {
      return res.status(400).json({ success: false, message: 'staffId and date are required' });
    }
    const targetDate = new Date(date + 'T00:00:00.000Z');
    const leave = await Leave.findOne({
      where: {
        staff_id: staffId,
        status: 'approved',
        from_date: { [Op.lte]: targetDate },
        to_date: { [Op.gte]: targetDate }
      }
    });
    return res.status(200).json({
      success: true,
      data: {
        hasApprovedLeave: leave !== null,
        leave: leave || null
      }
    });
  } catch (error) {
    console.error(`[${new Date().toISOString()}] checkApprovedLeave error: ${error.message}`);
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

// GET /api/leaves/my-leaves
exports.getMyLeaves = async (req, res) => {
  try {
    const staff_id = req.user.staff_id;
    if (!staff_id) return res.status(400).json({ success: false, message: 'No staff profile linked' });
    const leaves = await Leave.findAll({ where: { staff_id }, order: [['created_at', 'DESC']] });
    return res.status(200).json({ success: true, data: leaves });
  } catch (error) {
    console.error(`[${new Date().toISOString()}] Get my leaves error: ${error.message}`);
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

// GET /api/leaves
exports.getAll = async (req, res) => {
  try {
    const leaves = await Leave.findAll({ order: [['created_at', 'DESC']] });
    return res.status(200).json({ success: true, data: leaves });
  } catch (error) {
    console.error(`[${new Date().toISOString()}] Get leaves error: ${error.message}`);
    if (error.name === 'SequelizeConnectionError') return res.status(503).json({ success: false, message: 'Database unavailable' });
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

// POST /api/leaves
exports.apply = async (req, res) => {
  try {
    const staff_id = req.user.staff_id;
    if (!staff_id) return res.status(400).json({ success: false, message: 'No staff profile linked' });

    let { from_date, to_date, reason } = req.body;
    if (!from_date) return res.status(400).json({ success: false, message: 'From date is required' });
    if (!to_date) return res.status(400).json({ success: false, message: 'To date is required' });

    const fromDateObj = new Date(from_date + 'T00:00:00');
    const toDateObj = new Date(to_date + 'T00:00:00');
    if (isNaN(fromDateObj.getTime())) return res.status(400).json({ success: false, message: 'Invalid from date format' });
    if (isNaN(toDateObj.getTime())) return res.status(400).json({ success: false, message: 'Invalid to date format' });

    const today = new Date(); today.setHours(0, 0, 0, 0);
    if (fromDateObj < today) return res.status(400).json({ success: false, message: 'Cannot apply leave for past dates' });
    if (toDateObj < fromDateObj) return res.status(400).json({ success: false, message: 'End date cannot be before start date' });

    const diffDays = Math.ceil((toDateObj - fromDateObj) / (1000 * 60 * 60 * 24)) + 1;
    if (diffDays > 30) return res.status(400).json({ success: false, message: 'Leave duration cannot exceed 30 days' });

    if (!reason || !reason.trim()) return res.status(400).json({ success: false, message: 'Reason for leave is required' });
    reason = reason.trim();
    if (reason.length < 10) return res.status(400).json({ success: false, message: 'Please provide more detail (minimum 10 characters)' });
    if (reason.length > 500) return res.status(400).json({ success: false, message: 'Reason cannot exceed 500 characters' });

    const overlap = await Leave.findOne({
      where: {
        staff_id,
        status: { [Op.in]: ['pending', 'approved'] },
        from_date: { [Op.lte]: to_date },
        to_date: { [Op.gte]: from_date }
      }
    });
    if (overlap) return res.status(409).json({ success: false, message: `You already have a leave request for overlapping dates. Status: ${overlap.status}` });

    const leave = await Leave.create({ staff_id, from_date, to_date, reason });
    console.log(`[${new Date().toISOString()}] Leave applied by staff ${staff_id}: ${from_date} to ${to_date}`);
    return res.status(201).json({ success: true, data: leave });
  } catch (error) {
    console.error(`[${new Date().toISOString()}] Apply leave error: ${error.message}`);
    if (error.name === 'SequelizeConnectionError') return res.status(503).json({ success: false, message: 'Database unavailable' });
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
};

// PUT /api/leaves/:id
exports.updateStatus = async (req, res) => {
  try {
    const { status } = req.body;
    if (!status) return res.status(400).json({ success: false, message: 'Status is required' });
    if (!['approved', 'rejected'].includes(status)) return res.status(400).json({ success: false, message: "Status must be 'approved' or 'rejected'" });

    const leave = await Leave.findByPk(req.params.id);
    if (!leave) return res.status(404).json({ success: false, message: 'Leave request not found' });
    if (leave.status !== 'pending') return res.status(400).json({ success: false, message: `This leave has already been ${leave.status}` });

    leave.status = status;
    if (req.user && req.user.user_id) leave.approved_by = req.user.user_id;
    await leave.save();

    let shiftMessage = null;
    if (status === 'approved') {
      try {
        const cancelResponse = await axios.put(
          `${SHIFT_SERVICE_URL}/api/shifts/cancel-by-leave`,
          { staffId: leave.staff_id, fromDate: leave.from_date, toDate: leave.to_date },
          { timeout: 5000 }
        );
        const cancelledCount = cancelResponse.data?.data?.cancelledCount || 0;
        shiftMessage = `Leave approved. ${cancelledCount} shift(s) cancelled.`;
        console.log(`[${new Date().toISOString()}] Cancelled ${cancelledCount} shifts for leave ${req.params.id}`);
      } catch (error) {
        console.error(`[${new Date().toISOString()}] Shift cancellation failed: ${error.message}`);
        shiftMessage = 'Leave approved but could not auto-cancel shifts. Please cancel them manually.';
      }
    }

    console.log(`[${new Date().toISOString()}] Leave ${req.params.id} ${status} by admin`);
    const response = { success: true, data: leave };
    if (shiftMessage) response.message = shiftMessage;
    return res.status(200).json(response);
  } catch (error) {
    console.error(`[${new Date().toISOString()}] Update leave status error: ${error.message}`);
    if (error.name === 'SequelizeConnectionError') return res.status(503).json({ success: false, message: 'Database unavailable' });
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
};
