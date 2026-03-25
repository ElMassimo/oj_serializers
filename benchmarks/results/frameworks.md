# json_serializers: Framework Comparison Benchmark Results

Ruby 3.3.6 (x86_64-linux) — 2026-03-25

## AlbumSerializer: single model

| Framework | Iterations/s | Std Dev |
|---|---:|---:|
| json_serializers | 9.7k i/s | ±2.4% | **fastest** |
| panko | 5.7k i/s | ±4.0% | 1.7x slower |
| alba | 3.6k i/s | ±1.15% | 2.7x slower |
| blueprinter | 3.5k i/s | ±5.12% | 2.8x slower |
| active_model_serializers | 3.3k i/s | ±3.71% | 2.9x slower |

## AlbumSerializer: 100 albums

| Framework | Iterations/s | Std Dev |
|---|---:|---:|
| json_serializers | 101.9 i/s | ±0.98% | **fastest** |
| panko | 67.1 i/s | ±1.49% | 1.5x slower |
| blueprinter | 36.5 i/s | ±2.74% | 2.8x slower |
| alba | 34.2 i/s | ±2.92% | 3.0x slower |
| active_model_serializers | 33.5 i/s | ±2.98% | 3.0x slower |

## AlbumSerializer: 1000 albums

| Framework | Iterations/s | Std Dev |
|---|---:|---:|
| json_serializers | 9.7 i/s | ±10.29% | **fastest** |
| panko | 6.4 i/s | ±0.0% | 1.5x slower |
| blueprinter | 3.5 i/s | ±0.0% | 2.8x slower |
| alba | 3.5 i/s | ±0.0% | 2.8x slower |
| active_model_serializers | 3.3 i/s | ±0.0% | 2.9x slower |

## GameSerializer: single model

| Framework | Iterations/s | Std Dev |
|---|---:|---:|
| json_serializers | 56.8k i/s | ±1.53% | **fastest** |
| panko | 35.1k i/s | ±6.06% | 1.6x slower |

## ModelSerializer: 100 albums

| Framework | Iterations/s | Std Dev |
|---|---:|---:|
| panko | 1.0k i/s | ±1.91% | **fastest** |
| json_serializers | 1.0k i/s | ±2.8% | 1.0x slower |
| alba | 686.0 i/s | ±2.33% | 1.5x slower |
| blueprinter | 573.7 i/s | ±2.27% | 1.8x slower |
| active_model_serializers | 495.4 i/s | ±2.83% | 2.1x slower |

## OptionSerializer: 100 albums

| Framework | Iterations/s | Std Dev |
|---|---:|---:|
| panko | 6.9k i/s | ±3.43% | **fastest** |
| map_models | 4.5k i/s | ±1.32% | 1.5x slower |
| json_serializers | 4.2k i/s | ±2.3% | 1.6x slower |
| alba | 1.7k i/s | ±3.32% | 4.0x slower |
| blueprinter | 1.2k i/s | ±1.88% | 5.8x slower |
| active_model_serializers | 863.8 i/s | ±3.13% | 7.9x slower |

