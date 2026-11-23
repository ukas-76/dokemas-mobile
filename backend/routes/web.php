<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return response()->json([
        'status' => 'online',
        'app' => 'DOKEMAS Backend API',
        'message' => 'Selamat datang di DOKEMAS API Server (Banyumas)',
        'version' => '1.0.0',
        'database' => 'Connected (TiDB Cloud Serverless)',
        'documentation' => [
            'destinations' => url('/api/destinations'),
            'categories' => url('/api/categories'),
            'mitra_register' => url('/api/mitra/register'),
        ]
    ]);
});

Route::get('/api', function () {
    return response()->json([
        'status' => 'online',
        'app' => 'DOKEMAS Backend API',
        'message' => 'DOKEMAS Banyumas API is running successfully.',
        'version' => '1.0.0',
    ]);
});

Route::get('/api/', function () {
    return response()->json([
        'status' => 'online',
        'app' => 'DOKEMAS Backend API',
        'message' => 'DOKEMAS Banyumas API is running successfully.',
        'version' => '1.0.0',
    ]);
});

