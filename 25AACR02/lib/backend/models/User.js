const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
    firstName: {
        type: String,
        required: false,
    },
    lastName: {
        type: String,
        required: false,
    },
    name: {
        type: String,
        required: false,
    },
    email: {
        type: String,
        required: true,
        unique: true,
        lowercase: true,
    },
    password: {
        type: String,
        required: true,
    },
    phone: {
        type: String,
        required: false,
    },
    bio: {
        type: String,
        required: false,
    },
    location: {
        type: String,
        required: false,
    },
    dateOfBirth: {
        type: Date,
        required: false,
    },
    gender: {
        type: String,
        required: false,
    },
    education: {
        type: String,
        required: false,
    },
    currentlyWorking: {
        type: String,
        required: false,
    },
    profession: {
        type: String,
        required: false,
    },
    skillsRequired: [{
        type: String,
    }],
    skillsOffered: [{
        type: String,
    }],
    skills: [{
        type: String,
    }],
    profileImage: {
        type: String,
        required: false,
    },
    logo: {
        type: String,
        required: false,
    },
    fcmToken: {
        type: String,
        required: false, // For push notifications
    },
    createdAt: {
        type: Date,
        default: Date.now,
    },
    updatedAt: {
        type: Date,
        default: Date.now,
    }
});

// Update the updatedAt field before saving
userSchema.pre('save', function(next) {
    this.updatedAt = Date.now();
    next();
});

// Prevent OverwriteModelError during hot-reloads (nodemon) by reusing the compiled model if it exists
module.exports = mongoose.models.User || mongoose.model('User', userSchema);
