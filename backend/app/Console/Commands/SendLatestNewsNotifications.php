<?php

namespace App\Console\Commands;

use App\Models\DeviceToken;
use App\Models\NotificationLog;
use App\Services\FirebaseNotificationService;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Http;

class SendLatestNewsNotifications extends Command
{
    protected $signature = 'notifications:news';

    protected $description = 'Mengirim notifikasi berita terbaru Equityworld Futures';

    public function handle(
        FirebaseNotificationService $firebase
    ): int {
        $this->info('Memeriksa berita terbaru Equityworld Futures...');

        try {
            $response = Http::timeout(20)->get(
                'https://www.equityworld-futures.com/api/portalnews',
                [
                    'page' => 1,
                    'per_page' => 10,
                    'sort_by' => 'created_at',
                    'order' => 'desc',
                ]
            );

            if (! $response->successful()) {
                $this->error('Gagal mengambil berita dari sumber resmi.');

                return self::FAILURE;
            }

            $payload = $response->json();

            if (! is_array($payload) || ! isset($payload['data'])) {
                $this->error('Format berita dari API tidak valid.');

                return self::FAILURE;
            }

            $newsItems = $payload['data'];

        } catch (\Throwable $e) {
            report($e);
            $this->error('Gagal memeriksa berita: ' . $e->getMessage());

            return self::FAILURE;
        }

        $tokens = DeviceToken::query()
            ->whereNotNull('token')
            ->where('token', '!=', '')
            ->get();

        if ($tokens->isEmpty()) {
            $this->warn('Belum ada perangkat yang terdaftar.');

            return self::SUCCESS;
        }

        $sentCount = 0;

        foreach (array_slice($newsItems, 0, 1) as $item) {
            $newsId = $item['id'] ?? null;

            $title = trim(
                $item['titles']['ewf']
                ?? $item['title']
                ?? ''
            );

            if (! $newsId || $title === '') {
                continue;
            }

            $referenceKey = 'news_' . $newsId;

            if (NotificationLog::where(
                'reference_key',
                $referenceKey
            )->exists()) {
                continue;
            }

            $body = trim(strip_tags(
                $item['content'] ?? ''
            ));

            $body = preg_replace('/\s+/', ' ', $body);
            $body = mb_substr($body, 0, 180);

            if ($body === '') {
                $body = 'Ada berita terbaru dari Equityworld Futures.';
            }

            $success = true;

            foreach ($tokens as $device) {
                try {
                    $firebase->sendToToken(
                        $device->token,
                        'Berita Terbaru Equityworld Futures',
                        $title,
                        [
                            'type' => 'news',
                            'news_id' => $newsId,
                            'title' => $title,
                        ]
                    );
                } catch (\Throwable $e) {
                    $success = false;

                    report($e);

                    $this->warn(
                        'Gagal mengirim ke salah satu perangkat: '
                        . $device->id
                    );
                }
            }

            if ($success) {
                NotificationLog::create([
                    'type' => 'news',
                    'reference_key' => $referenceKey,
                    'title' => $title,
                    'body' => $body,
                    'sent_at' => now(),
                ]);

                $sentCount++;
                $this->info('Berita terkirim: ' . $title);
            } else {
                $this->warn(
                    'Sebagian pengiriman gagal. Berita akan dicoba kembali.'
                );
            }
        }

        $this->info(
            'Pemeriksaan selesai. Berita baru terkirim: '
            . $sentCount
        );

        return self::SUCCESS;
    }
}
