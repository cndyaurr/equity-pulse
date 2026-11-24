<?php

namespace App\Services;

use Kreait\Firebase\Factory;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;

class FirebaseNotificationService
{
    protected function messaging()
    {
        $credentials = config('services.firebase.credentials');

        if (!is_file($credentials)) {
            throw new \RuntimeException(
                'Firebase Service Account tidak ditemukan.'
            );
        }

        return (new Factory())
            ->withServiceAccount($credentials)
            ->createMessaging();
    }

    public function sendToToken(
        string $token,
        string $title,
        string $body,
        array $data = []
    ): array {
        $messageData = [];

        foreach ($data as $key => $value) {
            $messageData[(string) $key] = is_scalar($value)
                ? (string) $value
                : json_encode($value);
        }

        $message = CloudMessage::new()
            ->withToken($token)
            ->withNotification(
                Notification::create($title, $body)
            )
            ->withData($messageData);

        return $this->messaging()->send($message);
    }
}