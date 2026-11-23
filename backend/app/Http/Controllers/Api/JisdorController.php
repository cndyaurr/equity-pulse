<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Cache;
use Illuminate\Http\JsonResponse;
use Throwable;

class JisdorController extends Controller
{
    public function index(): JsonResponse
    {
        $cacheKey = 'bi_jisdor_latest';

        try {
            
$response = Http::withHeaders([
    'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/157.0.0.0 Safari/537.36',
    'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language' => 'id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7',
])
->timeout(30)
->get(
    'https://www.bi.go.id/biwebservice/wskursbi.asmx/getSubKursJisdor1?'
);

            if (!$response->successful()) {
                throw new \Exception('Gagal mengambil data dari Bank Indonesia.');
            }

            $xml = new \DOMDocument();

            if (!$xml->loadXML($response->body())) {
                throw new \Exception('Format XML tidak valid.');
            }

            $xpath = new \DOMXPath($xml);
            $tables = $xpath->query('//*[local-name()="Table"]');

            $records = [];

            foreach ($tables as $table) {
                $record = [];

                foreach ($table->childNodes as $child) {
                    if ($child instanceof \DOMElement) {
                        $record[$child->nodeName] = trim($child->textContent);
                    }
                }

                if (
                    strtoupper(trim($record['mts_subkursasing'] ?? '')) === 'USD'
                    && isset(
                        $record['beli_subkursasing'],
                        $record['jual_subkursasing'],
                        $record['tgl_subkursasing']
                    )
                ) {
                    $records[] = $record;
                }
            }

            if (empty($records)) {
                throw new \Exception('Data kurs USD tidak ditemukan.');
            }

            usort($records, function ($a, $b) {
                return strtotime($b['tgl_subkursasing'])
                    <=> strtotime($a['tgl_subkursasing']);
            });

            $latest = $records[0];

            \Log::info('BI JISDOR DEBUG', [
    'jumlah_data' => count($records),
    'tanggal_terpilih' => $latest['tgl_subkursasing'],
    'tanggal_berikutnya' => $records[1]['tgl_subkursasing'] ?? null,
    'kurs_terpilih' => $latest['beli_subkursasing'],
]);

            $buy = (float) $latest['beli_subkursasing'];
            $sell = (float) $latest['jual_subkursasing'];

            $data = [
                'success' => true,
                'source' => 'Bank Indonesia - JISDOR',
                'currency' => 'USD/IDR',
                'rate' => ($buy + $sell) / 2,
                'buy' => $buy,
                'sell' => $sell,
                'date' => \Carbon\Carbon::parse($latest['tgl_subkursasing'])
    ->format('Y-m-d'),
                'updated_at' => now()->toIso8601String(),
            ];

            Cache::put($cacheKey, $data, now()->addMinutes(15));

            return response()->json($data);

        } catch (Throwable $e) {
            $cachedData = Cache::get($cacheKey);

            if ($cachedData) {
                $cachedData['cached'] = true;
                return response()->json($cachedData);
            }

            return response()->json([
                'success' => false,
                'message' => 'Data JISDOR tidak dapat diambil.',
                'error' => $e->getMessage(),
            ], 503);
        }
    }
}
