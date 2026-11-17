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

# Read data
df = pd.read_csv('evaluation_results.csv')

# Map names to required names
name_mapping = {
    'BM25 tanpa Stemming': 'BM25',
    'BM25 dengan Stemming': 'BM25 + Stemming',
    'TF-IDF dengan Stemming': 'TF-IDF'
}
df['Method'] = df['Method'].replace(name_mapping)

# Colors for the bars
colors = ['#555555', '#999999', '#DDDDDD']
edge_color = 'black'

# --- Chart 1: Grouped Bar Chart ---
metrics = ['Precision', 'Recall', 'F1', 'P@5', 'P@10']
methods = ['BM25', 'BM25 + Stemming', 'TF-IDF']

fig, ax = plt.subplots(figsize=(10, 6), dpi=300)

x = np.arange(len(metrics))
width = 0.25

for i, method in enumerate(methods):
    values = df[df['Method'] == method][metrics].values[0]
    ax.bar(x + (i - 1) * width, values, width, label=method, color=colors[i], edgecolor=edge_color, zorder=3)

ax.set_ylabel('Score', fontsize=12, color='black')
ax.set_title('Comparison of Retrieval Performance', fontsize=14, fontweight='bold', color='black', pad=15)
ax.set_xticks(x)
ax.set_xticklabels(metrics, fontsize=11, color='black')
ax.legend(title='Algorithms', fontsize=10, title_fontsize=11)
ax.set_ylim(0, 1.1)

# Add grid lines behind bars
ax.grid(axis='y', linestyle='--', alpha=0.7, zorder=0, color='gray')

# Value labels on top of bars
for i, method in enumerate(methods):
    values = df[df['Method'] == method][metrics].values[0]
    for j, val in enumerate(values):
        ax.text(j + (i - 1) * width, val + 0.015, f'{val:.4f}', ha='center', va='bottom', fontsize=9, rotation=90, color='black')

plt.tight_layout()
plt.savefig('retrieval_performance.png', format='png', dpi=300, bbox_inches='tight')
plt.savefig('retrieval_performance.svg', format='svg', bbox_inches='tight')
plt.close()

# --- Chart 2: Vertical Bar Chart ---
fig, ax = plt.subplots(figsize=(8, 6), dpi=300)

x_methods = np.arange(len(methods))
times = [df[df['Method'] == method]['Avg Time (ms)'].values[0] for method in methods]

bars = ax.bar(x_methods, times, width=0.5, color=colors, edgecolor=edge_color, zorder=3)

ax.set_ylabel('Average Query Time (ms)', fontsize=12, color='black')
ax.set_title('Comparison of Average Query Time', fontsize=14, fontweight='bold', color='black', pad=15)
ax.set_xticks(x_methods)
ax.set_xticklabels(methods, fontsize=11, color='black')
ax.set_ylim(0, max(times) * 1.2) # Add some space for labels

# Add grid lines behind bars
ax.grid(axis='y', linestyle='--', alpha=0.7, zorder=0, color='gray')

# Value labels on top of bars
for bar in bars:
    yval = bar.get_height()
    ax.text(bar.get_x() + bar.get_width()/2, yval + (max(times) * 0.02), f'{yval:.2f}', ha='center', va='bottom', fontsize=11, color='black')

plt.tight_layout()
plt.savefig('average_query_time.png', format='png', dpi=300, bbox_inches='tight')
plt.savefig('average_query_time.svg', format='svg', bbox_inches='tight')
plt.close()
