const router = require('express').Router();
const { authenticate, requireAdmin } = require('../middleware/auth');
const auth = require('../controllers/authController');
const hotel = require('../controllers/hotelController');
const booking = require('../controllers/bookingController');
const admin = require('../controllers/adminController');
const favorite = require('../controllers/favoriteController');

// Auth
router.post('/auth/register', auth.register);
router.post('/auth/login', auth.login);
router.get('/auth/me', authenticate, auth.me);
router.put('/auth/me', authenticate, auth.updateMe);

// Hotel & kamar (publik)
router.get('/hotels', hotel.list);
router.get('/hotels/cities', hotel.cities);
router.get('/hotels/:id', hotel.detail);
router.get('/rooms/:id/availability', hotel.roomAvailability);
router.post('/hotels/:id/reviews', authenticate, hotel.addReview);
router.get('/reviews/me', authenticate, hotel.myReviews);

// Hotel disukai (favorit)
router.get('/favorites', authenticate, favorite.list);
router.post('/hotels/:id/favorite', authenticate, favorite.add);
router.delete('/hotels/:id/favorite', authenticate, favorite.remove);

// Booking (login)
router.post('/bookings', authenticate, booking.create);
router.get('/bookings', authenticate, booking.myBookings);
router.get('/bookings/:id', authenticate, booking.detail);
router.post('/bookings/:id/payment', authenticate, booking.createPayment);
router.patch('/bookings/:id/pay', authenticate, booking.pay);
router.patch('/bookings/:id/cancel', authenticate, booking.cancel);

// Admin
router.use('/admin', authenticate, requireAdmin);
router.get('/admin/stats', admin.stats);
router.post('/admin/hotels', admin.createHotel);
router.put('/admin/hotels/:id', admin.updateHotel);
router.delete('/admin/hotels/:id', admin.deleteHotel);
router.post('/admin/rooms', admin.createRoom);
router.put('/admin/rooms/:id', admin.updateRoom);
router.delete('/admin/rooms/:id', admin.deleteRoom);
router.get('/admin/bookings', admin.allBookings);
router.get('/admin/rooms/booked', admin.bookedRooms);
router.get('/admin/reviews', admin.allReviews);
router.delete('/admin/reviews/:id', admin.deleteReview);
router.patch('/admin/bookings/:id/status', admin.updateBookingStatus);

module.exports = router;
