import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

# Use a professional style
plt.rcParams['font.family'] = 'serif'
plt.rcParams['font.serif'] = ['Times New Roman', 'DejaVu Serif', 'serif']
plt.rcParams['axes.facecolor'] = 'white'
plt.rcParams['figure.facecolor'] = 'white'
plt.rcParams['text.color'] = 'black'
plt.rcParams['axes.labelcolor'] = 'black'
plt.rcParams['xtick.color'] = 'black'
plt.rcParams['ytick.color'] = 'black'
plt.rcParams['axes.edgecolor'] = 'black'

# Read optimized data
df = pd.read_csv('evaluation_results_optimized.csv')

# Map names to required names
name_mapping = {
    'BM25 tanpa Stemming': 'BM25',
    'BM25 dengan Stemming': 'BM25 + Stemming',
    'TF-IDF dengan Stemming': 'TF-IDF'
}
df['Method'] = df['Method'].replace(name_mapping)

methods = ['BM25', 'BM25 + Stemming', 'TF-IDF']
colors = ['#555555', '#999999', '#DDDDDD']
edge_color = 'black'

# --- Chart 2: Vertical Bar Chart ---
fig, ax = plt.subplots(figsize=(8, 6), dpi=300)

x_methods = np.arange(len(methods))
times = [df[df['Method'] == method]['Avg Time (ms)'].values[0] for method in methods]

bars = ax.bar(x_methods, times, width=0.5, color=colors, edgecolor=edge_color, zorder=3)

ax.set_ylabel('Average Query Time (ms)', fontsize=12, color='black')
ax.set_title('Comparison of Average Query Time', fontsize=14, fontweight='bold', color='black', pad=15)
ax.set_xticks(x_methods)
ax.set_xticklabels(methods, fontsize=11, color='black')

# Automatically scale Y-axis based on the final values
max_val = max(times)
# Let's set a compact range up to roughly max_val * 1.3
ax.set_ylim(0, max_val * 1.3)

# Add grid lines behind bars
ax.grid(axis='y', linestyle='--', alpha=0.7, zorder=0, color='gray')

# Value labels on top of bars
for bar in bars:
    yval = bar.get_height()
    ax.text(bar.get_x() + bar.get_width()/2, yval + (max_val * 0.03), f'{yval:.2f}', ha='center', va='bottom', fontsize=11, color='black')

plt.tight_layout()
plt.savefig('average_query_time.png', format='png', dpi=300, bbox_inches='tight')
plt.savefig('average_query_time.svg', format='svg', bbox_inches='tight')
plt.close()
