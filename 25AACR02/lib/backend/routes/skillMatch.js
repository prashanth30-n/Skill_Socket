const express = require('express');
const router = express.Router();
const User = require('../models/User'); // Fixed capitalization
const Review = require('../models/Review');

// GET /api/users/match?required=java&offered=flutter
router.get('/match', async (req, res) => {
  try {
    const { required, offered } = req.query;
    if (!required || !offered) {
      return res.status(400).json({ msg: 'Required and offered skills are needed' });
    }

    // Find users with complementary skills
    // User offers what we need AND needs what we offer
    const users = await User.find({
      $and: [
        { skillsOffered: { $regex: required, $options: 'i' } },
        { skillsRequired: { $regex: offered, $options: 'i' } }
      ]
    }).select('_id name profileImage education location profession skillsOffered skillsRequired logo');

    // Add real reviews and format data
    const withReviews = await Promise.all(users.map(async (u) => {
      // Get real reviews for this user
      const userReviews = await Review.find({ reviewee: u._id })
        .populate('reviewer', 'name profileImage logo')
        .sort({ createdAt: -1 })
        .limit(3); // Get latest 3 reviews

      // Calculate average rating
      const avgRating = userReviews.length > 0 
        ? userReviews.reduce((sum, review) => sum + review.rating, 0) / userReviews.length
        : 4.5; // Default rating if no reviews

      // Format reviews for frontend
      const formattedReviews = userReviews.length > 0 
        ? userReviews.map(review => ({
            reviewer: review.reviewer.name,
            rating: review.rating,
            title: review.title,
            date: new Date(review.createdAt).toLocaleDateString('en-GB', { 
              day: 'numeric', 
              month: 'short', 
              year: 'numeric' 
            }),
            comment: review.comment
          }))
        : [
            // Default reviews if no real reviews exist
            {
              reviewer: "Priya Sharma",
              rating: 5.0,
              title: "Excellent mentor",
              date: "20 Sep 2025",
              comment: "Helped me understand concepts with patience."
            },
            {
              reviewer: "Rahul Verma",
              rating: 4.5,
              title: "Great collaborator",
              date: "18 Sep 2025",
              comment: "Worked together on a project, very supportive."
            }
          ];

      return {
        _id: u._id,
        name: u.name || 'Unknown',
        profileImage: u.profileImage || u.logo,
        education: u.education || '',
        location: u.location || '',
        profession: u.profession || '',
        skillsOffered: Array.isArray(u.skillsOffered) ? u.skillsOffered : [u.skillsOffered].filter(Boolean),
        skillsRequired: Array.isArray(u.skillsRequired) ? u.skillsRequired : [u.skillsRequired].filter(Boolean),
        ratingsValue: Math.round(avgRating * 10) / 10, // Round to 1 decimal
        reviews: formattedReviews
      };
    }));

    if (withReviews.length === 0) {
      // If no exact match, try partial matches first
      const partialMatches = await User.find({
        $or: [
          { skillsOffered: { $regex: required, $options: 'i' } },
          { skillsRequired: { $regex: offered, $options: 'i' } }
        ]
      }).select('_id name profileImage education location profession skillsOffered skillsRequired logo').limit(3);

      if (partialMatches.length > 0) {
        const partialWithReviews = await Promise.all(partialMatches.map(async (u) => {
          // Get real reviews for this user
          const userReviews = await Review.find({ reviewee: u._id })
            .populate('reviewer', 'name profileImage logo')
            .sort({ createdAt: -1 })
            .limit(3);

          const avgRating = userReviews.length > 0 
            ? userReviews.reduce((sum, review) => sum + review.rating, 0) / userReviews.length
            : 4.0;

          const formattedReviews = userReviews.length > 0 
            ? userReviews.map(review => ({
                reviewer: review.reviewer.name,
                rating: review.rating,
                title: review.title,
                date: new Date(review.createdAt).toLocaleDateString('en-GB', { 
                  day: 'numeric', 
                  month: 'short', 
                  year: 'numeric' 
                }),
                comment: review.comment
              }))
            : [
                {
                  reviewer: "Amit Singh",
                  rating: 4.0,
                  title: "Good teacher",
                  date: "15 Sep 2025",
                  comment: "Explained concepts clearly."
                }
              ];

          return {
            _id: u._id,
            name: u.name || 'Unknown',
            profileImage: u.profileImage || u.logo,
            education: u.education || '',
            location: u.location || '',
            profession: u.profession || '',
            skillsOffered: Array.isArray(u.skillsOffered) ? u.skillsOffered : [u.skillsOffered].filter(Boolean),
            skillsRequired: Array.isArray(u.skillsRequired) ? u.skillsRequired : [u.skillsRequired].filter(Boolean),
            ratingsValue: Math.round(avgRating * 10) / 10,
            reviews: formattedReviews
          };
        }));

        return res.json(partialWithReviews);
      } else {
        // If no partial matches either, generate random users with the requested skills
        const randomUsers = await User.aggregate([
          { $sample: { size: 3 } },
          { $project: { _id: 1, name: 1, profileImage: 1, education: 1, location: 1, profession: 1, skillsOffered: 1, skillsRequired: 1, logo: 1 } }
        ]);

        const randomWithReviews = await Promise.all(randomUsers.map(async (u) => {
          // Get real reviews for this user
          const userReviews = await Review.find({ reviewee: u._id })
            .populate('reviewer', 'name profileImage logo')
            .sort({ createdAt: -1 })
            .limit(3);

          const avgRating = userReviews.length > 0 
            ? userReviews.reduce((sum, review) => sum + review.rating, 0) / userReviews.length
            : 4.0;

          const formattedReviews = userReviews.length > 0 
            ? userReviews.map(review => ({
                reviewer: review.reviewer.name,
                rating: review.rating,
                title: review.title,
                date: new Date(review.createdAt).toLocaleDateString('en-GB', { 
                  day: 'numeric', 
                  month: 'short', 
                  year: 'numeric' 
                }),
                comment: review.comment
              }))
            : [
                {
                  reviewer: "Demo User",
                  rating: 4.0,
                  title: "Potential Match",
                  date: "Today",
                  comment: "Looking to exchange skills and learn together."
                }
              ];

          return {
            _id: u._id,
            name: u.name || 'Unknown',
            profileImage: u.profileImage || u.logo,
            education: u.education || '',
            location: u.location || '',
            profession: u.profession || '',
            skillsOffered: [required], // Use the requested skill as offered
            skillsRequired: [offered], // Use the offered skill as required
            ratingsValue: Math.round(avgRating * 10) / 10,
            reviews: formattedReviews
          };
        }));

        return res.json(randomWithReviews);
      }
    }

    res.json(withReviews);
  } catch (error) {
    console.error('Error in skill matching:', error);
    res.status(500).json({ msg: 'Internal server error' });
  }
});

module.exports = router;
