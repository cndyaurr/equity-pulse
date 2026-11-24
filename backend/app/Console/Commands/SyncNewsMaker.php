<?php

namespace App\Console\Commands;

use App\Models\GoldPrice;
use Carbon\Carbon;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Http;

class SyncNewsMaker extends Command
{
    protected $signature = 'newsmaker:sync';

    protected $description = 'Sinkronisasi data LGD, HSI, dan SNI dari News Maker';

    public function handle(): int
    {
        $this->info('Mengambil data dari News Maker API...');

        try {
            $response = Http::timeout(120)->get(
                'https://www.newsmaker.id/api/historical-data'
            );
        } catch (\Throwable $e) {
            $this->error('Gagal mengakses News Maker: ' . $e->getMessage());
            return self::FAILURE;
        }

        if (!$response->successful()) {
            $this->error('HTTP Error: ' . $response->status());
            return self::FAILURE;
        }

        $json = $response->json();

        if (!is_array($json) || !isset($json['data']) || !is_array($json['data'])) {
            $this->error('Respons News Maker tidak valid.');
            return self::FAILURE;
        }

        $rows = $json['data'];

        $this->info('Total data dari API: ' . count($rows));

        $commodities = [
            'LGD Daily' => 'LGD',
            'HSI Daily' => 'HSI',
            'SNI Daily' => 'SNI',
        ];

        $grouped = [
            'LGD' => [],
            'HSI' => [],
            'SNI' => [],
        ];

        $skippedDates = 0;

        foreach ($rows as $row) {
            if (!is_array($row)) {
                continue;
            }

            $category = $row['category'] ?? null;

            if (!isset($commodities[$category])) {
                continue;
            }

            $commodity = $commodities[$category];

            // Validasi tanggal berlaku untuk semua komoditas.
            $rawDate = trim((string) ($row['tanggal'] ?? ''));

            $date = \DateTimeImmutable::createFromFormat('!Y-m-d', $rawDate);
            $errors = \DateTimeImmutable::getLastErrors();

            $validDate = $date !== false
                && ($errors === false || (
                    $errors['warning_count'] === 0
                    && $errors['error_count'] === 0
                ))
                && $date->format('Y-m-d') === $rawDate
                && preg_match('/^[1-9]\d{3}-\d{2}-\d{2}$/', $rawDate);

            if (!$validDate) {
                $this->warn(
                    "Melewati {$category}, ID "
                    . ($row['id'] ?? '?')
                    . ", tanggal tidak valid: {$rawDate}"
                );

                $skippedDates++;
                continue;
            }

            // Pastikan seluruh nilai OHLC tersedia dan numerik.
            $fields = ['open', 'high', 'low', 'close'];

            $validPrices = true;

            foreach ($fields as $field) {
                if (
                    !isset($row[$field])
                    || $row[$field] === ''
                    || !is_numeric($row[$field])
                ) {
                    $validPrices = false;
                    break;
                }
            }

            if (!$validPrices) {
                continue;
            }

            $row['_validated_date'] = $rawDate;

            $grouped[$commodity][$rawDate] = $row;
        }

        $totals = [];

        foreach ($grouped as $commodity => $items) {
            ksort($items);
            $grouped[$commodity] = array_values($items);

            $totals[$commodity] = [
                'inserted' => 0,
                'updated' => 0,
            ];

            $this->info(
                "Total {$commodity} Daily valid: " . count($items)
            );
        }

        if (
            empty($grouped['LGD'])
            && empty($grouped['HSI'])
            && empty($grouped['SNI'])
        ) {
            $this->error('Tidak ada data valid untuk disinkronkan.');
            return self::FAILURE;
        }

        foreach ($grouped as $commodity => $items) {
            foreach ($items as $row) {
                $rawDate = $row['_validated_date'];

                $date = Carbon::createFromFormat(
                    '!Y-m-d',
                    $rawDate
                )->endOfDay();

                $existing = GoldPrice::where('commodity', $commodity)
                    ->whereDate('recorded_at', $rawDate)
                    ->first();

                $payload = [
                    'commodity' => $commodity,
                    'price' => (float) $row['close'],
                    'open' => (float) $row['open'],
                    'high' => (float) $row['high'],
                    'low' => (float) $row['low'],
                    'close' => (float) $row['close'],
                    'recorded_at' => $date,
                ];

                if ($existing) {
                    $existing->update($payload);
                    $totals[$commodity]['updated']++;
                } else {
                    GoldPrice::create($payload);
                    $totals[$commodity]['inserted']++;
                }
            }
        }

        $this->newLine();
        $this->info('Sinkronisasi selesai!');

        foreach ($totals as $commodity => $total) {
            $this->line("{$commodity} baru ditambahkan : {$total['inserted']}");
            $this->line("{$commodity} diperbarui       : {$total['updated']}");
            $this->line("Total {$commodity} valid       : " . count($grouped[$commodity]));
        }

        $this->line("Tanggal dilewati             : {$skippedDates}");

        foreach (['LGD', 'HSI', 'SNI'] as $commodity) {
            $latest = GoldPrice::where('commodity', $commodity)
                ->orderByDesc('recorded_at')
                ->first();

            if (!$latest) {
                continue;
            }

            $this->newLine();
            $this->info("DATA {$commodity} TERBARU DI DATABASE:");
            $this->line('Tanggal : ' . $latest->recorded_at->format('Y-m-d'));
            $this->line('Open    : ' . $latest->open);
            $this->line('High    : ' . $latest->high);
            $this->line('Low     : ' . $latest->low);
            $this->line('Close   : ' . $latest->close);
        }

        return self::SUCCESS;
    }
}
