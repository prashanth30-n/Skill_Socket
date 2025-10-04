const express = require('express');
const router = express.Router();
const User = require('../models/User'); // Using consistent capitalization
const verifyToken = require('../middlewares/verifyToken');

// Get user profile
router.get('/profile', verifyToken, async (req, res) => { // Added verifyToken middleware
    try {
        console.log('📋 Get user profile called');
        console.log('📋 req.user:', req.user);
        
        // Validate authentication
        if (!req.user || !req.user.userId) {
            console.log('📋 Authentication failed - no user or userId');
            return res.status(401).json({ msg: 'Authentication required' });
        }

        const userId = req.user.userId;
        const userProfile = await User.findById(userId).select('-password');
        
        if (!userProfile) {
            return res.status(404).json({ msg: "User not found" });
        }
        
        console.log('📋 User profile found:', userProfile);
        res.json({ user: userProfile });
    } catch (err) {
        console.error('Get profile error:', err);
        res.status(500).json({ msg: "Internal server error" });
    }
});

// Get user profile by ID (public)
router.get('/profile/:userId', async (req, res) => {
    try {
        const userId = req.params.userId;
        const userProfile = await User.findById(userId).select('-password');
        if (!userProfile) {
            return res.status(404).json({ msg: "User not found" });
        }
        res.json({ user: userProfile });
    } catch (err) {
        console.error('Get profile by ID error:', err);
        res.status(500).json({ msg: "Internal server error" });
    }
});

// Update user profile
router.put('/profile', verifyToken, async (req, res) => { // Changed from '/update' to '/profile' for consistency
    try {
        console.log('📝 Update user profile called');
        console.log('📝 req.user:', req.user);
        console.log('📝 req.body:', req.body);
        
        // Validate authentication
        if (!req.user || !req.user.userId) {
            console.log('📝 Authentication failed - no user or userId');
            return res.status(401).json({ msg: 'Authentication required' });
        }

        const userId = req.user.userId;
        
        // Extract allowed fields from request body
        const allowedFields = ['name', 'phone', 'bio', 'location', 'dateOfBirth', 'skills', 'profileImage', 'education', 'profession', 'currentlyWorking', 'skillsRequired', 'skillsOffered'];
        const updateData = {};
        
        allowedFields.forEach(field => {
            if (req.body[field] !== undefined) {
                updateData[field] = req.body[field];
            }
        });

        // Handle skills array
        if (req.body.skills && typeof req.body.skills === 'string') {
            updateData.skills = req.body.skills.split(',').map(skill => skill.trim());
        }

        // Handle date of birth
        if (req.body.dateOfBirth) {
            updateData.dateOfBirth = new Date(req.body.dateOfBirth);
        }

        console.log('📝 Update data:', updateData);

        const updatedUser = await User.findByIdAndUpdate(
            userId,
            updateData,
            { new: true, runValidators: true }
        ).select('-password');
        
        if (!updatedUser) {
            return res.status(404).json({ msg: "User not found" });
        }
        
        console.log('📝 Profile updated successfully:', updatedUser);
        res.json({ msg: "Profile updated successfully", user: updatedUser });

    } catch (err) {
        console.error('Update profile error:', err);
        res.status(500).json({ msg: "Internal server error" });
    }
});

// Update FCM token for push notifications
router.put('/fcm-token', verifyToken, async (req, res) => {
    try {
        console.log('📱 Update FCM token called');
        const userId = req.user.userId;
        const { fcmToken } = req.body;

        if (!fcmToken) {
            return res.status(400).json({ msg: 'FCM token is required' });
        }

        const updatedUser = await User.findByIdAndUpdate(
            userId,
            { fcmToken },
            { new: true }
        ).select('-password');

        if (!updatedUser) {
            return res.status(404).json({ msg: "User not found" });
        }

        console.log('📱 FCM token updated successfully');
        res.json({ 
            msg: "FCM token updated successfully", 
            user: updatedUser 
        });

    } catch (err) {
        console.error('Update FCM token error:', err);
        res.status(500).json({ msg: "Internal server error" });
    }
});

module.exports = router;