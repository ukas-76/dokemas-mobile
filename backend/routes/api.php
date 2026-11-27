<?php

use App\Http\Controllers\Api\Admin\DashboardController;
use App\Http\Controllers\Api\Admin\UserController as AdminUserController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\DestinationController;
use App\Http\Controllers\Api\FacilityController;
use App\Http\Controllers\Api\ItineraryController;
use App\Http\Controllers\Api\ConversationController;
use App\Http\Controllers\Api\ReviewController;
use App\Http\Controllers\Api\WishlistController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Public routes (guest)
|--------------------------------------------------------------------------
*/
Route::get('/', function () {
    return response()->json([
        'status' => 'online',
        'app' => 'DOKEMAS API',
        'message' => 'Backend API DOKEMAS Banyumas is running successfully.',
        'version' => '1.0.0',
    ]);
});

Route::get('register', function () {
    return response()->json(['message' => 'Method GET not allowed. Use POST to register.'], 405);
});
Route::post('register', [AuthController::class, 'register']);
Route::get('login', function () {
    return response()->json(['message' => 'Unauthenticated.'], 401);
})->name('login');
Route::post('login', [AuthController::class, 'login']);

// Pendaftaran Mitra dari Website (Form 4 Langkah)
Route::post('mitra/register', [\App\Http\Controllers\Api\MitraRegistrationController::class, 'register']);

// Password Reset Routes
Route::post('forgot-password', [\App\Http\Controllers\Api\PasswordResetController::class, 'forgotPassword']);
Route::post('verify-otp', [\App\Http\Controllers\Api\PasswordResetController::class, 'verifyOtp']);
Route::post('reset-password', [\App\Http\Controllers\Api\PasswordResetController::class, 'resetPassword']);

Route::get('categories', [CategoryController::class, 'index']);
Route::get('categories/{category}', [CategoryController::class, 'show']);
Route::get('facilities', [FacilityController::class, 'index']);
Route::get('destinations', [DestinationController::class, 'index']);
Route::get('destinations/{destination}', [DestinationController::class, 'show']);
Route::get('destinations/{destination}/nearby-accommodations', [DestinationController::class, 'nearbyAccommodations']);
Route::get('destinations/{destination}/reviews', [ReviewController::class, 'index']);

/*
|--------------------------------------------------------------------------
| Authenticated routes (user)
|--------------------------------------------------------------------------
*/
Route::middleware('auth:sanctum')->group(function () {
    // Account
    Route::get('me', [AuthController::class, 'me']);
    Route::post('logout', [AuthController::class, 'logout']);
    Route::put('profile', [AuthController::class, 'updateProfile']);
    // upload avatar (multipart -> pakai POST; field: avatar)
    Route::post('profile/avatar', [AuthController::class, 'updateProfile']);

    // Reviews
    Route::get('me/reviews', [ReviewController::class, 'myReviews']);
    Route::post('destinations/{destination}/reviews', [ReviewController::class, 'store']);
    Route::put('reviews/{review}', [ReviewController::class, 'update']);
    Route::delete('reviews/{review}', [ReviewController::class, 'destroy']);
    Route::post('reviews/{review}/reply', [ReviewController::class, 'reply']);
    Route::post('mitra/reviews/{review}/reply', [ReviewController::class, 'reply']);

    // Wishlist
    Route::get('wishlist', [WishlistController::class, 'index']);
    Route::post('wishlist', [WishlistController::class, 'store']);
    Route::post('wishlist/toggle', [WishlistController::class, 'toggle']);
    Route::delete('wishlist/{destination}', [WishlistController::class, 'destroy']);

    // Chat / Percakapan
    Route::get('conversations/unread-count', [ConversationController::class, 'unreadCount']);
    Route::get('conversations', [ConversationController::class, 'index']);
    Route::post('conversations', [ConversationController::class, 'store']);
    Route::get('conversations/{id}/messages', [ConversationController::class, 'messages']);
    Route::post('conversations/{id}/messages', [ConversationController::class, 'sendMessage']);

    // Portal Mitra (Pendaftaran & Manajemen Destinasi)
    Route::get('mitra/status', [\App\Http\Controllers\Api\MitraRegistrationController::class, 'status']);
    Route::get('mitra/destinations', [\App\Http\Controllers\Api\Mitra\DestinationController::class, 'index']);
    Route::post('mitra/destinations', [\App\Http\Controllers\Api\Mitra\DestinationController::class, 'store']);
    Route::get('mitra/destinations/{destination}', [\App\Http\Controllers\Api\Mitra\DestinationController::class, 'show']);
    Route::match(['put', 'patch'], 'mitra/destinations/{destination}', [\App\Http\Controllers\Api\Mitra\DestinationController::class, 'update']);
    Route::post('mitra/destinations/{destination}/images', [\App\Http\Controllers\Api\Mitra\DestinationController::class, 'uploadImages']);
    Route::post('mitra/destinations/{destination}/set-cover', [\App\Http\Controllers\Api\Mitra\DestinationController::class, 'setCover']);
    Route::delete('mitra/destinations/{destination}/images/{image}', [\App\Http\Controllers\Api\Mitra\DestinationController::class, 'deleteImage']);

    // Itineraries
    Route::apiResource('itineraries', ItineraryController::class);
    Route::post('itineraries/{itinerary}/items', [ItineraryController::class, 'addItem']);
    Route::delete('itineraries/{itinerary}/items/{item}', [ItineraryController::class, 'removeItem']);

    /*
    |----------------------------------------------------------------------
    | Admin routes
    |----------------------------------------------------------------------
    */
    Route::middleware('admin')->prefix('admin')->group(function () {
        Route::get('/', function () {
            return response()->json(['message' => 'DOKEMAS Admin API Base Route']);
        });
        Route::get('dashboard', DashboardController::class);

        Route::apiResource('categories', CategoryController::class)->except(['index', 'show']);
        Route::apiResource('facilities', FacilityController::class)->except(['index']);
        Route::apiResource('destinations', DestinationController::class)->except(['index', 'show']);
        Route::patch('destinations/{destination}/status', [DestinationController::class, 'updateStatus']);
        Route::apiResource('users', AdminUserController::class);
        Route::get('reviews', [\App\Http\Controllers\Api\Admin\ReviewController::class, 'index']);
        Route::patch('reviews/{review}/status', [\App\Http\Controllers\Api\Admin\ReviewController::class, 'updateStatus']);
        Route::delete('reviews/{review}', [\App\Http\Controllers\Api\Admin\ReviewController::class, 'destroy']);

        // Manajemen Kemitraan (Kurasi Dinporabudpar)
        Route::get('mitra-applications', [\App\Http\Controllers\Api\Admin\MitraManagementController::class, 'index']);
        Route::get('mitra-applications/{id}', [\App\Http\Controllers\Api\Admin\MitraManagementController::class, 'show']);
        Route::post('mitra-applications/{id}/approve', [\App\Http\Controllers\Api\Admin\MitraManagementController::class, 'approve']);
        Route::post('mitra-applications/{id}/reject', [\App\Http\Controllers\Api\Admin\MitraManagementController::class, 'reject']);

        // Galeri foto destinasi (upload auto-convert ke WebP)
        Route::post('destinations/{destination}/images', [DestinationController::class, 'uploadImages']);
        Route::delete('destination-images/{image}', [DestinationController::class, 'deleteImage']);
    });
});