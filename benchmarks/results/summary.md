# oj_serializers: Oj vs Ruby JSON Benchmark Results

| Scenario | json | oj |
|---|---:|---:|
| One Object (as_json) | 9.7k i/s | 14.8k i/s |
| One Object (as_hash) | 16.3k i/s | 15.0k i/s |
| 100 Albums (as_json) | 103.6 i/s | 159.4 i/s |
| 100 Albums (as_hash) | 166.4 i/s | 155.8 i/s |
| 1000 Albums (as_json) | 9.4 i/s | 15.7 i/s |
| 1000 Albums (as_hash) | 15.2 i/s | 16.1 i/s |
