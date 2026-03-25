# frozen_string_literal: true

# Generates an HTML comparison chart from framework benchmark results.
#
# Usage:
#   ruby benchmarks/generate_framework_charts.rb
#
# Reads benchmarks/results/frameworks.json and produces:
#   - benchmarks/results/frameworks.html (interactive Chart.js visualization)
#   - benchmarks/results/frameworks.md  (markdown summary table)

require 'json'

RESULTS_DIR = File.expand_path('results', __dir__)
INPUT_FILE = File.join(RESULTS_DIR, 'frameworks.json')

unless File.exist?(INPUT_FILE)
  abort "No results file found at #{INPUT_FILE}. Run benchmarks first:\n  BENCHMARK=\"true\" bin/rspec benchmarks --pattern \"**/*_benchmark.rb\""
end

data = JSON.parse(File.read(INPUT_FILE), symbolize_names: true)
metadata = data[:metadata]
scenarios = data[:scenarios]

puts "Loaded framework benchmark results:"
puts "  Ruby #{metadata[:ruby_version]} (#{metadata[:ruby_platform]})"
puts "  YJIT: #{metadata[:yjit]}"
puts "  #{scenarios.length} scenario(s): #{scenarios.keys.join(', ')}"

# Framework colors — consistent across all charts.
COLORS = {
  'json_serializers' => { bg: 'rgba(54, 162, 235, 0.8)', border: 'rgba(54, 162, 235, 1)' },
  'panko' => { bg: 'rgba(255, 159, 64, 0.8)', border: 'rgba(255, 159, 64, 1)' },
  'blueprinter' => { bg: 'rgba(75, 192, 192, 0.8)', border: 'rgba(75, 192, 192, 1)' },
  'active_model_serializers' => { bg: 'rgba(255, 99, 132, 0.8)', border: 'rgba(255, 99, 132, 1)' },
  'alba' => { bg: 'rgba(153, 102, 255, 0.8)', border: 'rgba(153, 102, 255, 1)' },
  'map_models' => { bg: 'rgba(201, 203, 207, 0.8)', border: 'rgba(201, 203, 207, 1)' },
}
DEFAULT_COLOR = { bg: 'rgba(128, 128, 128, 0.5)', border: 'rgba(128, 128, 128, 1)' }

def color_for(label)
  COLORS[label] || DEFAULT_COLOR
end

def format_ips(ips)
  if ips >= 1_000_000
    "#{(ips / 1_000_000.0).round(1)}M i/s"
  elsif ips >= 1000
    "#{(ips / 1000.0).round(1)}k i/s"
  else
    "#{ips.round(1)} i/s"
  end
end

# Filter to only serializer-comparison scenarios (skip accessor benchmarks).
serializer_scenarios = scenarios.select { |name, _|
  name.to_s.include?('Serializer')
}

# Collect all unique framework labels across serializer scenarios.
all_labels = serializer_scenarios.values.flatten.map { |e| e[:label] }.uniq

# Build per-scenario chart data.
chart_data = serializer_scenarios.map do |scenario_name, entries|
  {
    name: scenario_name.to_s,
    labels: entries.map { |e| e[:label] },
    values: entries.map { |e| e[:ips] },
    colors_bg: entries.map { |e| color_for(e[:label])[:bg] },
    colors_border: entries.map { |e| color_for(e[:label])[:border] },
  }
end

# Build overview chart — one group per scenario, one bar per framework.
overview_labels = chart_data.map { |cd| cd[:name] }
overview_frameworks = all_labels.select { |l| COLORS.key?(l) }

overview_datasets = overview_frameworks.map do |fw|
  {
    label: fw,
    data: chart_data.map { |cd|
      idx = cd[:labels].index(fw)
      idx ? cd[:values][idx] : 0
    },
    backgroundColor: color_for(fw)[:bg],
    borderColor: color_for(fw)[:border],
    borderWidth: 1,
  }
end

# Build markdown summary.
md_lines = []
md_lines << "# json_serializers: Framework Comparison Benchmark Results"
md_lines << ""
md_lines << "Ruby #{metadata[:ruby_version]} (#{metadata[:ruby_platform]})#{metadata[:yjit] ? ' with YJIT' : ''} — #{metadata[:timestamp]&.split('T')&.first}"
md_lines << ""

serializer_scenarios.each do |scenario_name, entries|
  md_lines << "## #{scenario_name}"
  md_lines << ""
  md_lines << "| Framework | Iterations/s | Std Dev |"
  md_lines << "|---|---:|---:|"

  sorted = entries.sort_by { |e| -e[:ips] }
  best_ips = sorted.first[:ips]

  sorted.each do |entry|
    ratio = entry[:ips] == best_ips ? '**fastest**' : "#{(best_ips / entry[:ips]).round(1)}x slower"
    md_lines << "| #{entry[:label]} | #{format_ips(entry[:ips])} | ±#{entry[:stddev_pct]}% | #{ratio} |"
  end
  md_lines << ""
end

# Build HTML.
html = <<~HTML
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>json_serializers: Framework Comparison Benchmark</title>
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
  <h1>json_serializers: Framework Comparison</h1>
  <p class="subtitle">Comparing json_serializers against other Ruby serialization libraries</p>

  <div class="metadata">
    <span><strong>Ruby:</strong> #{metadata[:ruby_version]}</span>
    <span><strong>Platform:</strong> #{metadata[:ruby_platform]}</span>
    <span><strong>YJIT:</strong> #{metadata[:yjit] || false}</span>
    <span><strong>JSON gem:</strong> #{metadata[:json_version]}</span>
    <span><strong>Date:</strong> #{metadata[:timestamp]&.split('T')&.first}</span>
  </div>

  <div class="chart-container">
    <h2>Overview: Iterations per Second (higher is better)</h2>
    <canvas id="overviewChart"></canvas>
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
    #{serializer_scenarios.map { |scenario_name, entries|
      sorted = entries.sort_by { |e| -e[:ips] }
      best_ips = sorted.first[:ips]
      <<~TABLE
      <h3 style="margin: 1rem 0 0.5rem; color: #555; font-size: 1rem;">#{scenario_name}</h3>
      <table>
        <thead>
          <tr><th>Framework</th><th>Iterations/s</th><th>vs fastest</th></tr>
        </thead>
        <tbody>
          #{sorted.map { |entry|
            cls = entry[:ips] == best_ips ? ' class="winner"' : ''
            ratio = entry[:ips] == best_ips ? 'fastest' : "#{(best_ips / entry[:ips]).round(1)}x slower"
            "<tr#{cls}><td>#{entry[:label]}</td><td>#{format_ips(entry[:ips])}</td><td>#{ratio}</td></tr>"
          }.join("\n          ")}
        </tbody>
      </table>
      TABLE
    }.join("\n  ")}
  </div>

  <script>
    function fmtIps(val) {
      if (val >= 1000000) return (val/1000000).toFixed(1) + 'M';
      if (val >= 1000) return (val/1000).toFixed(1) + 'k';
      return val.toFixed(0);
    }

    const tooltipCallback = {
      label: function(ctx) {
        return ctx.dataset.label + ': ' + fmtIps(ctx.parsed.y || ctx.parsed.x) + ' i/s';
      }
    };

    const yScaleIps = {
      beginAtZero: true,
      title: { display: true, text: 'Iterations per second' },
      ticks: { callback: function(val) { return fmtIps(val); } }
    };

    const xScaleIps = {
      beginAtZero: true,
      title: { display: true, text: 'Iterations per second' },
      ticks: { callback: function(val) { return fmtIps(val); } }
    };

    // Overview chart
    new Chart(document.getElementById('overviewChart'), {
      type: 'bar',
      data: {
        labels: #{JSON.generate(overview_labels)},
        datasets: #{JSON.generate(overview_datasets)}
      },
      options: {
        responsive: true,
        interaction: { mode: 'index', intersect: false },
        plugins: { tooltip: { callbacks: tooltipCallback } },
        scales: { y: yScaleIps }
      }
    });

    // Individual scenario charts (horizontal bars)
    #{chart_data.map.with_index { |cd, i| <<~JS
    new Chart(document.getElementById('chart#{i}'), {
      type: 'bar',
      data: {
        labels: #{JSON.generate(cd[:labels])},
        datasets: [{
          data: #{JSON.generate(cd[:values])},
          backgroundColor: #{JSON.generate(cd[:colors_bg])},
          borderColor: #{JSON.generate(cd[:colors_border])},
          borderWidth: 1
        }]
      },
      options: {
        responsive: true,
        indexAxis: 'y',
        plugins: {
          legend: { display: false },
          tooltip: {
            callbacks: {
              label: function(ctx) { return fmtIps(ctx.parsed.x) + ' i/s'; }
            }
          }
        },
        scales: { x: xScaleIps }
      }
    });
    JS
    }.join}
  </script>
</body>
</html>
HTML

# Write outputs.
html_file = File.join(RESULTS_DIR, 'frameworks.html')
File.write(html_file, html)
puts "Chart generated: #{html_file}"

md_file = File.join(RESULTS_DIR, 'frameworks.md')
File.write(md_file, md_lines.join("\n") + "\n")
puts "Summary generated: #{md_file}"
