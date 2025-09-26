const express = require('express');
const { body, validationResult } = require('express-validator');
const auth = require('../middleware/auth');
const User = require('../models/User');

const router = express.Router();

// @route   POST /api/calls/start
// @desc    Start a new call
// @access  Private
router.post('/start', auth, [
    body('recipientId')
        .notEmpty()
        .withMessage('Recipient ID is required'),
    body('callType')
        .isIn(['voice', 'video'])
        .withMessage('Call type must be either voice or video')
], async (req, res) => {
    try {
        // Check for validation errors
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({
                message: 'Validation failed',
                errors: errors.array()
            });
        }

        const { recipientId, callType } = req.body;
        const callerId = req.user._id;

        // Check if recipient exists
        const recipient = await User.findById(recipientId);
        if (!recipient) {
            return res.status(404).json({
                message: 'Recipient not found'
            });
        }

        // Check if caller is trying to call themselves
        if (callerId === recipientId) {
            return res.status(400).json({
                message: 'Cannot call yourself'
            });
        }

        // Generate a unique call ID
        const callId = require('uuid').v4();

        // Create call object
        const call = {
            id: callId,
            callerId,
            recipientId,
            callType,
            status: 'ringing',
            startTime: new Date()
        };

        // Store call in memory (in production, use Redis or database)
        if (!global.activeCalls) {
            global.activeCalls = new Map();
        }
        global.activeCalls.set(callId, call);

        // Send call notification via Socket.IO
        const io = req.app.get('io');
        if (io) {
            io.to(`user_${recipientId}`).emit('incoming_call', {
                callId,
                callerId,
                callerName: req.user.displayName,
                callerUsername: req.user.username,
                callType,
                timestamp: new Date()
            });
        }

        res.json({
            message: 'Call started successfully',
            callId,
            call
        });

    } catch (error) {
        console.error('Start call error:', error);
        res.status(500).json({
            message: 'Server error while starting call'
        });
    }
});

// @route   POST /api/calls/accept
// @desc    Accept an incoming call
// @access  Private
router.post('/accept', auth, [
    body('callId')
        .notEmpty()
        .withMessage('Call ID is required'),
    body('callType')
        .isIn(['voice', 'video'])
        .withMessage('Call type must be either voice or video')
], async (req, res) => {
    try {
        // Check for validation errors
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({
                message: 'Validation failed',
                errors: errors.array()
            });
        }

        const { callId, callType } = req.body;
        const userId = req.user._id;

        // Get call from memory
        if (!global.activeCalls) {
            return res.status(404).json({
                message: 'Call not found'
            });
        }

        const call = global.activeCalls.get(callId);
        if (!call) {
            return res.status(404).json({
                message: 'Call not found'
            });
        }

        // Check if user is the recipient
        if (call.recipientId !== userId) {
            return res.status(403).json({
                message: 'You are not authorized to accept this call'
            });
        }

        // Update call status
        call.status = 'connected';
        call.acceptedAt = new Date();
        global.activeCalls.set(callId, call);

        // Notify caller that call was accepted
        const io = req.app.get('io');
        if (io) {
            io.to(`user_${call.callerId}`).emit('call_accepted', {
                callId,
                callType,
                timestamp: new Date()
            });
        }

        res.json({
            message: 'Call accepted successfully',
            callId,
            call
        });

    } catch (error) {
        console.error('Accept call error:', error);
        res.status(500).json({
            message: 'Server error while accepting call'
        });
    }
});

// @route   POST /api/calls/reject
// @desc    Reject an incoming call
// @access  Private
router.post('/reject', auth, [
    body('callId')
        .notEmpty()
        .withMessage('Call ID is required')
], async (req, res) => {
    try {
        // Check for validation errors
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({
                message: 'Validation failed',
                errors: errors.array()
            });
        }

        const { callId } = req.body;
        const userId = req.user._id;

        // Get call from memory
        if (!global.activeCalls) {
            return res.status(404).json({
                message: 'Call not found'
            });
        }

        const call = global.activeCalls.get(callId);
        if (!call) {
            return res.status(404).json({
                message: 'Call not found'
            });
        }

        // Check if user is the recipient
        if (call.recipientId !== userId) {
            return res.status(403).json({
                message: 'You are not authorized to reject this call'
            });
        }

        // Update call status
        call.status = 'rejected';
        call.rejectedAt = new Date();
        global.activeCalls.set(callId, call);

        // Notify caller that call was rejected
        const io = req.app.get('io');
        if (io) {
            io.to(`user_${call.callerId}`).emit('call_rejected', {
                callId,
                timestamp: new Date()
            });
        }

        res.json({
            message: 'Call rejected successfully'
        });

    } catch (error) {
        console.error('Reject call error:', error);
        res.status(500).json({
            message: 'Server error while rejecting call'
        });
    }
});

// @route   POST /api/calls/end
// @desc    End an active call
// @access  Private
router.post('/end', auth, [
    body('callId')
        .notEmpty()
        .withMessage('Call ID is required')
], async (req, res) => {
    try {
        // Check for validation errors
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({
                message: 'Validation failed',
                errors: errors.array()
            });
        }

        const { callId } = req.body;
        const userId = req.user._id;

        // Get call from memory
        if (!global.activeCalls) {
            return res.status(404).json({
                message: 'Call not found'
            });
        }

        const call = global.activeCalls.get(callId);
        if (!call) {
            return res.status(404).json({
                message: 'Call not found'
            });
        }

        // Check if user is part of the call
        if (call.callerId !== userId && call.recipientId !== userId) {
            return res.status(403).json({
                message: 'You are not authorized to end this call'
            });
        }

        // Update call status
        call.status = 'ended';
        call.endedAt = new Date();
        global.activeCalls.set(callId, call);

        // Notify other participant that call was ended
        const otherParticipantId = call.callerId === userId ? call.recipientId : call.callerId;
        const io = req.app.get('io');
        if (io) {
            io.to(`user_${otherParticipantId}`).emit('call_ended', {
                callId,
                endedBy: userId,
                timestamp: new Date()
            });
        }

        res.json({
            message: 'Call ended successfully'
        });

    } catch (error) {
        console.error('End call error:', error);
        res.status(500).json({
            message: 'Server error while ending call'
        });
    }
});

// @route   POST /api/calls/offer
// @desc    Send WebRTC offer
// @access  Private
router.post('/offer', auth, [
    body('callId')
        .notEmpty()
        .withMessage('Call ID is required'),
    body('offer')
        .notEmpty()
        .withMessage('Offer is required')
], async (req, res) => {
    try {
        // Check for validation errors
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({
                message: 'Validation failed',
                errors: errors.array()
            });
        }

        const { callId, offer } = req.body;
        const userId = req.user._id;

        // Get call from memory
        if (!global.activeCalls) {
            return res.status(404).json({
                message: 'Call not found'
            });
        }

        const call = global.activeCalls.get(callId);
        if (!call) {
            return res.status(404).json({
                message: 'Call not found'
            });
        }

        // Check if user is part of the call
        if (call.callerId !== userId && call.recipientId !== userId) {
            return res.status(403).json({
                message: 'You are not authorized for this call'
            });
        }

        // Send offer to other participant
        const otherParticipantId = call.callerId === userId ? call.recipientId : call.callerId;
        const io = req.app.get('io');
        if (io) {
            io.to(`user_${otherParticipantId}`).emit('webrtc_offer', {
                callId,
                offer,
                from: userId,
                timestamp: new Date()
            });
        }

        res.json({
            message: 'Offer sent successfully'
        });

    } catch (error) {
        console.error('Send offer error:', error);
        res.status(500).json({
            message: 'Server error while sending offer'
        });
    }
});

// @route   POST /api/calls/answer
// @desc    Send WebRTC answer
// @access  Private
router.post('/answer', auth, [
    body('callId')
        .notEmpty()
        .withMessage('Call ID is required'),
    body('answer')
        .notEmpty()
        .withMessage('Answer is required')
], async (req, res) => {
    try {
        // Check for validation errors
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({
                message: 'Validation failed',
                errors: errors.array()
            });
        }

        const { callId, answer } = req.body;
        const userId = req.user._id;

        // Get call from memory
        if (!global.activeCalls) {
            return res.status(404).json({
                message: 'Call not found'
            });
        }

        const call = global.activeCalls.get(callId);
        if (!call) {
            return res.status(404).json({
                message: 'Call not found'
            });
        }

        // Check if user is part of the call
        if (call.callerId !== userId && call.recipientId !== userId) {
            return res.status(403).json({
                message: 'You are not authorized for this call'
            });
        }

        // Send answer to other participant
        const otherParticipantId = call.callerId === userId ? call.recipientId : call.callerId;
        const io = req.app.get('io');
        if (io) {
            io.to(`user_${otherParticipantId}`).emit('webrtc_answer', {
                callId,
                answer,
                from: userId,
                timestamp: new Date()
            });
        }

        res.json({
            message: 'Answer sent successfully'
        });

    } catch (error) {
        console.error('Send answer error:', error);
        res.status(500).json({
            message: 'Server error while sending answer'
        });
    }
});

// @route   POST /api/calls/ice-candidate
// @desc    Send WebRTC ICE candidate
// @access  Private
router.post('/ice-candidate', auth, [
    body('callId')
        .notEmpty()
        .withMessage('Call ID is required'),
    body('candidate')
        .notEmpty()
        .withMessage('ICE candidate is required')
], async (req, res) => {
    try {
        // Check for validation errors
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({
                message: 'Validation failed',
                errors: errors.array()
            });
        }

        const { callId, candidate } = req.body;
        const userId = req.user._id;

        // Get call from memory
        if (!global.activeCalls) {
            return res.status(404).json({
                message: 'Call not found'
            });
        }

        const call = global.activeCalls.get(callId);
        if (!call) {
            return res.status(404).json({
                message: 'Call not found'
            });
        }

        // Check if user is part of the call
        if (call.callerId !== userId && call.recipientId !== userId) {
            return res.status(403).json({
                message: 'You are not authorized for this call'
            });
        }

        // Send ICE candidate to other participant
        const otherParticipantId = call.callerId === userId ? call.recipientId : call.callerId;
        const io = req.app.get('io');
        if (io) {
            io.to(`user_${otherParticipantId}`).emit('webrtc_ice_candidate', {
                callId,
                candidate,
                from: userId,
                timestamp: new Date()
            });
        }

        res.json({
            message: 'ICE candidate sent successfully'
        });

    } catch (error) {
        console.error('Send ICE candidate error:', error);
        res.status(500).json({
            message: 'Server error while sending ICE candidate'
        });
    }
});

module.exports = router;
