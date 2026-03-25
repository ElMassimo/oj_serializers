# frozen_string_literal: true

# Generates an HTML comparison chart from benchmark results.
#
# Usage:
#   ruby benchmarks/generate_charts.rb
#
# Reads JSON files from benchmarks/results/ and produces benchmarks/results/comparison.html

require 'json'

RESULTS_DIR = File.expand_path('results', __dir__)

# Load all result files
result_files = Dir[File.join(RESULTS_DIR, '*.json')].sort
if result_files.empty?
  abort "No result files found in #{RESULTS_DIR}. Run benchmarks first."
end

all_results = result_files.map { |f| JSON.parse(File.read(f), symbolize_names: true) }

puts "Loaded #{all_results.length} result file(s):"
all_results.each do |r|
  m = r[:metadata]
  yjit_label = m[:yjit] ? 'YJIT' : 'no YJIT'
  puts "  - #{m[:backend]} (#{yjit_label}) — Ruby #{m[:ruby_version]}, #{m[:timestamp]}"
end

# Organize data by scenario
# Each scenario (e.g. "one object") has sub-modes (as_json, as_hash) and backends (oj, json) x (yjit, no_yjit)
scenarios = {
  'One Object' => { pattern: /^one object/ },
  '100 Albums' => { pattern: /^100 albums/ },
  '1000 Albums' => { pattern: /^1000 albums/ },
}

# Build datasets for the chart
# Each dataset is a bar group: "oj as_json (no YJIT)", "oj as_hash (no YJIT)", "json as_json (no YJIT)", etc.
colors = {
  'oj_as_json' => { bg: 'rgba(54, 162, 235, 0.8)', border: 'rgba(54, 162, 235, 1)' },
  'oj_as_hash' => { bg: 'rgba(54, 162, 235, 0.4)', border: 'rgba(54, 162, 235, 1)' },
  'oj_as_json_yjit' => { bg: 'rgba(30, 100, 180, 0.9)', border: 'rgba(30, 100, 180, 1)' },
  'oj_as_hash_yjit' => { bg: 'rgba(30, 100, 180, 0.5)', border: 'rgba(30, 100, 180, 1)' },
  'json_as_json' => { bg: 'rgba(75, 192, 192, 0.8)', border: 'rgba(75, 192, 192, 1)' },
  'json_as_hash' => { bg: 'rgba(75, 192, 192, 0.4)', border: 'rgba(75, 192, 192, 1)' },
  'json_as_json_yjit' => { bg: 'rgba(30, 140, 140, 0.9)', border: 'rgba(30, 140, 140, 1)' },
  'json_as_hash_yjit' => { bg: 'rgba(30, 140, 140, 0.5)', border: 'rgba(30, 140, 140, 1)' },
}

# Determine which configurations are present
configs = all_results.map { |r|
  m = r[:metadata]
  { backend: m[:backend], yjit: !!m[:yjit] }
}.uniq

# Build chart data per scenario
chart_data = scenarios.map do |scenario_name, opts|
  labels = []
  datasets_hash = {}

  configs.each do |config|
    result = all_results.find { |r|
      m = r[:metadata]
      m[:backend] == config[:backend] && !!m[:yjit] == config[:yjit]
    }
    next unless result

    yjit_suffix = config[:yjit] ? ' (YJIT)' : ''
    yjit_key = config[:yjit] ? '_yjit' : ''

    result[:results].each do |entry|
      next unless entry[:name] =~ opts[:pattern]

      mode = entry[:name].include?('as_json') ? 'as_json' : 'as_hash'
      dataset_key = "#{config[:backend]}_#{mode}#{yjit_key}"
      dataset_label = "#{config[:backend]} #{mode}#{yjit_suffix}"

      datasets_hash[dataset_key] ||= {
        label: dataset_label,
        data: [],
        backgroundColor: colors.dig(dataset_key, :bg) || 'rgba(128,128,128,0.5)',
        borderColor: colors.dig(dataset_key, :border) || 'rgba(128,128,128,1)',
        borderWidth: 1,
      }
      datasets_hash[dataset_key][:data] << entry[:ips]

      # Track unique scenario labels
      labels << scenario_name unless labels.include?(scenario_name)
    end
  end

  { name: scenario_name, labels: labels, datasets: datasets_hash.values }
end

# Build a combined overview chart
overview_labels = scenarios.keys
overview_datasets_hash = {}

configs.each do |config|
  result = all_results.find { |r|
    m = r[:metadata]
    m[:backend] == config[:backend] && !!m[:yjit] == config[:yjit]
  }
  next unless result

  yjit_suffix = config[:yjit] ? ' (YJIT)' : ''
  yjit_key = config[:yjit] ? '_yjit' : ''

  %w[as_json as_hash].each do |mode|
    dataset_key = "#{config[:backend]}_#{mode}#{yjit_key}"
    dataset_label = "#{config[:backend]} #{mode}#{yjit_suffix}"

    overview_datasets_hash[dataset_key] ||= {
      label: dataset_label,
      data: [],
      backgroundColor: colors.dig(dataset_key, :bg) || 'rgba(128,128,128,0.5)',
      borderColor: colors.dig(dataset_key, :border) || 'rgba(128,128,128,1)',
      borderWidth: 1,
    }

    scenarios.each do |_scenario_name, opts|
      entry = result[:results].find { |e| e[:name] =~ opts[:pattern] && e[:name].include?(mode) }
      overview_datasets_hash[dataset_key][:data] << (entry ? entry[:ips] : 0)
    end
  end
end

# Build markdown summary
md_lines = []
md_lines << "# json_serializers: Oj vs Ruby JSON Benchmark Results"
md_lines << ""
md_lines << "| Scenario | " + configs.map { |c|
  "#{c[:backend]}#{c[:yjit] ? ' (YJIT)' : ''}"
}.join(' | ') + " |"
md_lines << "|---|" + configs.map { '---:' }.join('|') + "|"

scenarios.each do |scenario_name, opts|
  %w[as_json as_hash].each do |mode|
    values = configs.map do |config|
      result = all_results.find { |r|
        m = r[:metadata]
        m[:backend] == config[:backend] && !!m[:yjit] == config[:yjit]
      }
      entry = result&.dig(:results)&.find { |e| e[:name] =~ opts[:pattern] && e[:name].include?(mode) }
      entry ? format_ips(entry[:ips]) : 'N/A'
    end
    md_lines << "| #{scenario_name} (#{mode}) | #{values.join(' | ')} |"
  end
end

# Helper for formatting
BEGIN {
  def format_ips(ips)
    if ips >= 1000
      "#{(ips / 1000.0).round(1)}k i/s"
    else
      "#{ips.round(1)} i/s"
    end
  end
}

metadata = all_results.first[:metadata]

html = <<~HTML
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>json_serializers: Oj vs Ruby JSON Benchmark</title>
  <script src="https://cdn.jsdelivr.net/npm/chart.js@4"></script>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      background: #f8f9fa;
      color: #333;
      padding: 2rem;
      max-width: 1200px;
      margin: 0 auto;
    }
    h1 { font-size: 1.8rem; margin-bottom: 0.5rem; }
    .subtitle { color: #666; margin-bottom: 2rem; font-size: 0.95rem; }
    .chart-container {
      background: white;
      border-radius: 12px;
      padding: 1.5rem;
      margin-bottom: 2rem;
      box-shadow: 0 1px 3px rgba(0,0,0,0.1);
    }
    .chart-container h2 {
      font-size: 1.2rem;
      margin-bottom: 1rem;
      color: #444;
    }
    canvas { max-height: 400px; }
    table {
      width: 100%;
      border-collapse: collapse;
      margin-top: 1rem;
      font-size: 0.9rem;
    }
    th, td {
      padding: 0.6rem 1rem;
      text-align: right;
      border-bottom: 1px solid #eee;
    }
    th { background: #f1f3f5; font-weight: 600; text-align: left; }
    td:first-child { text-align: left; font-weight: 500; }
    tr:hover { background: #f8f9fa; }
    .legend-note {
      font-size: 0.8rem;
      color: #888;
      margin-top: 0.5rem;
    }
    .metadata {
      font-size: 0.85rem;
      color: #666;
      margin-bottom: 1.5rem;
      padding: 1rem;
      background: white;
      border-radius: 8px;
      box-shadow: 0 1px 3px rgba(0,0,0,0.1);
    }
    .metadata span { margin-right: 2rem; }
    .winner { background: #e8f5e9 !important; font-weight: 600; }
  </style>
</head>
<body>
  <h1>json_serializers: Oj vs Ruby JSON Benchmark</h1>
  <p class="subtitle">Comparing Oj C extension with Ruby's built-in JSON gem for json_serializers</p>

  <div class="metadata">
    <span><strong>Ruby:</strong> #{metadata[:ruby_version]}</span>
    <span><strong>Platform:</strong> #{metadata[:ruby_platform]}</span>
    <span><strong>Oj:</strong> #{metadata[:oj_version] || 'N/A'}</span>
    <span><strong>JSON gem:</strong> #{metadata[:json_version]}</span>
    <span><strong>Date:</strong> #{metadata[:timestamp]&.split('T')&.first}</span>
  </div>

  <div class="chart-container">
    <h2>Overview: Iterations per Second (higher is better)</h2>
    <canvas id="overviewChart"></canvas>
    <p class="legend-note">
      <strong>as_json</strong> = streaming writer path (Oj::StringWriter or JsonWriter) &nbsp;|&nbsp;
      <strong>as_hash</strong> = build Hash then JSON.generate/Oj.dump
    </p>
  </div>

  #{chart_data.map.with_index { |cd, i| <<~CHART
  <div class="chart-container">
    <h2>#{cd[:name]}: Iterations per Second</h2>
    <canvas id="chart#{i}"></canvas>
  </div>
  CHART
  }.join}

  <div class="chart-container">
    <h2>Summary Table</h2>
    <table>
      <thead>
        <tr>
          <th>Scenario</th>
          #{configs.map { |c| "<th>#{c[:backend]}#{c[:yjit] ? ' (YJIT)' : ''}</th>" }.join("\n          ")}
        </tr>
      </thead>
      <tbody>
        #{scenarios.map { |scenario_name, opts|
          %w[as_json as_hash].map { |mode|
            values = configs.map { |config|
              result = all_results.find { |r|
                m = r[:metadata]
                m[:backend] == config[:backend] && !!m[:yjit] == config[:yjit]
              }
              entry = result&.dig(:results)&.find { |e| e[:name] =~ opts[:pattern] && e[:name].include?(mode) }
              entry ? entry[:ips] : 0
            }
            max_val = values.max
            cells = values.map { |v|
              cls = v == max_val && v > 0 ? ' class="winner"' : ''
              "<td#{cls}>#{v > 0 ? format_ips(v) : 'N/A'}</td>"
            }
            "<tr><td>#{scenario_name} (#{mode})</td>#{cells.join}</tr>"
          }.join("\n        ")
        }.join("\n        ")}
      </tbody>
    </table>
  </div>

  <script>
    const overviewData = {
      labels: #{JSON.generate(overview_labels)},
      datasets: #{JSON.generate(overview_datasets_hash.values)}
    };

    new Chart(document.getElementById('overviewChart'), {
      type: 'bar',
      data: overviewData,
      options: {
        responsive: true,
        interaction: { mode: 'index', intersect: false },
        plugins: {
          tooltip: {
            callbacks: {
              label: function(ctx) {
                let val = ctx.parsed.y;
                return ctx.dataset.label + ': ' + (val >= 1000 ? (val/1000).toFixed(1) + 'k' : val.toFixed(0)) + ' i/s';
              }
            }
          }
        },
        scales: {
          y: {
            beginAtZero: true,
            title: { display: true, text: 'Iterations per second' },
            ticks: {
              callback: function(val) { return val >= 1000 ? (val/1000) + 'k' : val; }
            }
          }
        }
      }
    });

    #{chart_data.map.with_index { |cd, i| <<~JS
    new Chart(document.getElementById('chart#{i}'), {
      type: 'bar',
      data: {
        labels: #{JSON.generate(cd[:labels])},
        datasets: #{JSON.generate(cd[:datasets])}
      },
      options: {
        responsive: true,
        indexAxis: 'y',
        plugins: {
          tooltip: {
            callbacks: {
              label: function(ctx) {
                let val = ctx.parsed.x;
                return ctx.dataset.label + ': ' + (val >= 1000 ? (val/1000).toFixed(1) + 'k' : val.toFixed(0)) + ' i/s';
              }
            }
          }
        },
        scales: {
          x: {
            beginAtZero: true,
            title: { display: true, text: 'Iterations per second' },
            ticks: {
              callback: function(val) { return val >= 1000 ? (val/1000) + 'k' : val; }
            }
          }
        }
      }
    });
    JS
    }.join}
  </script>
</body>
</html>
HTML

output_file = File.join(RESULTS_DIR, 'comparison.html')
File.write(output_file, html)
puts "Chart generated: #{output_file}"

# Also write markdown summary
md_file = File.join(RESULTS_DIR, 'summary.md')
File.write(md_file, md_lines.join("\n") + "\n")
puts "Summary generated: #{md_file}"
