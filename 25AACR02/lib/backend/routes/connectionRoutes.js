const express = require('express');
const router = express.Router();
const ConnectionRequest = require('../models/ConnectionRequest');
const NotificationService = require('../services/notificationService');
const verifyToken = require('../middlewares/verifyToken');

// Send connection request
router.post('/send', verifyToken, async (req, res) => {
    try {
        const fromUserId = req.user.userId;
        const { toUserId, message } = req.body;

        // Validate required fields
        if (!toUserId) {
            return res.status(400).json({ 
                success: false, 
                message: 'toUserId is required' 
            });
        }

        // Check if request already exists
        const existingRequest = await ConnectionRequest.findOne({
            from: fromUserId,
            to: toUserId
        });

        if (existingRequest) {
            return res.status(400).json({ 
                success: false, 
                message: 'Connection request already sent' 
            });
        }

        // Don't allow self-requests
        if (fromUserId === toUserId) {
            return res.status(400).json({ 
                success: false, 
                message: 'Cannot send request to yourself' 
            });
        }

        // Create new connection request
        const connectionRequest = new ConnectionRequest({
            from: fromUserId,
            to: toUserId,
            message: message || 'Would like to connect with you!'
        });

        await connectionRequest.save();

        // Populate the request with user details
        const populatedRequest = await ConnectionRequest.findById(connectionRequest._id)
            .populate('from', 'name profileImage logo email')
            .populate('to', 'name profileImage logo email');//populate is just like the join operation

        // Send notification to recipient
        await NotificationService.notifyConnectionRequest(fromUserId, toUserId, connectionRequest._id);

        res.status(201).json({
            success: true,
            message: 'Connection request sent successfully',
            data: populatedRequest
        });

    } catch (error) {
        console.error('Error sending connection request:', error);
        res.status(500).json({ 
            success: false, 
            message: 'Internal server error' 
        });
    }
});

// Get received connection requests (for notifications)
router.get('/received', verifyToken, async (req, res) => {
    try {
        const userId = req.user.userId;

        const requests = await ConnectionRequest.find({
            to: userId,
            status: 'pending'
        })
        .populate('from', 'name profileImage logo email')
        .sort({ createdAt: -1 });

        res.json({
            success: true,
            data: requests
        });

    } catch (error) {
        console.error('Error fetching connection requests:', error);
        res.status(500).json({ 
            success: false, 
            message: 'Internal server error' 
        });
    }
});

// Accept connection request
router.post('/accept/:requestId', verifyToken, async (req, res) => {
    try {
        const { requestId } = req.params;
        const userId = req.user.userId;

        const request = await ConnectionRequest.findById(requestId)
            .populate('from', 'name profileImage email');

        if (!request) {
            return res.status(404).json({ 
                success: false, 
                message: 'Connection request not found' 
            });
        }

        // Verify the request is for this user
        if (request.to.toString() !== userId) {
            return res.status(403).json({ 
                success: false, 
                message: 'Not authorized' 
            });
        }

        // Update request status
        request.status = 'accepted';
        await request.save();

        res.json({
            success: true,
            message: 'Connection request accepted',
            data: request
        });

    } catch (error) {
        console.error('Error accepting connection request:', error);
        res.status(500).json({ 
            success: false, 
            message: 'Internal server error' 
        });
    }
});

// Reject connection request
router.post('/reject/:requestId', verifyToken, async (req, res) => {
    try {
        const { requestId } = req.params;
        const userId = req.user.userId;

        const request = await ConnectionRequest.findById(requestId);

        if (!request) {
            return res.status(404).json({ 
                success: false, 
                message: 'Connection request not found' 
            });
        }

        // Verify the request is for this user
        if (request.to.toString() !== userId) {
            return res.status(403).json({ 
                success: false, 
                message: 'Not authorized' 
            });
        }

        // Update request status
        request.status = 'rejected';
        await request.save();

        res.json({
            success: true,
            message: 'Connection request rejected'
        });

    } catch (error) {
        console.error('Error rejecting connection request:', error);
        res.status(500).json({ 
            success: false, 
            message: 'Internal server error' 
        });
    }
});

// Get sent connection requests
router.get('/sent', verifyToken, async (req, res) => {
    try {
        const userId = req.user.userId;

        const requests = await ConnectionRequest.find({
            from: userId
        })
        .populate('to', 'name profileImage email')
        .sort({ createdAt: -1 });

        res.json({
            success: true,
            data: requests
        });

    } catch (error) {
        console.error('Error fetching sent requests:', error);
        res.status(500).json({ 
            success: false, 
            message: 'Internal server error' 
        });
    }
});

module.exports = router;
