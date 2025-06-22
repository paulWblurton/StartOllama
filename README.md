# StartOllama

StartOllama is an open-source toolkit for fetching, visualizing, and launching local large language models (LLMs) from the [Ollama Library](https://ollama.com/library). This project leverages PowerShell and Batch scripts to:
  
- **Scrape the Ollama Library:**  
  The `FetchModels.ps1` script extracts model names, titles, and descriptions from the Ollama Library and generates a Markdown catalog (`models_list.md`) in your system’s TEMP folder.

- **Generate a Feature-Rich Dashboard:**  
  `GenerateModelDashboard.ps1` builds an HTML dashboard (`models_catalog.html`) that includes:
  - A **scrollable, multi-column top navigation index** (wrapped in a fixed-height container) that lists all model links.
  - A **system requirements table** with standard ASCII punctuation, now positioned at the top of the dashboard.
  - Detailed sections for **each model**, each beginning with an H2 header (e.g., "Model: Qwen2.5-VL"), displaying the model’s description, any classification (if defined), the default command (e.g., `ollama run qwen2.5vl`), variants (if any), and a “Back to top” link.
  
- **Launch a Chosen Model:**  
  `LaunchLLM_AutoModelSelect.bat` (and its wrapper `StartOllama.bat`) generate the dashboard, open it in your default browser, and then prompt you to enter a model name (or variant) to launch via `ollama.exe`.

---

## Fixes & Improvements

- **UI & Layout Enhancements:**
  - Removed distracting progress indicators and flashing blue windows.
  - Added a scrollable, multi-column top navigation index with a fixed max-height (displaying roughly 5 rows).
  - Moved the system requirements table to the very top of the dashboard for quicker reference.
  - Added clear H2 section headers in each model’s detailed section.

- **Encoding & Text Fixes:**
  - Replaced unusual encoded characters (e.g., “GPTâ€‘2 Small” and “3Bâ€“7B models”) with plain ASCII text (e.g., “GPT-2 Small” and “3B-7B models”).
  - Standardized all prompt text (e.g., “Enter model to launch (e.g., qwen2.5vl or qwen2.5vl:32b):”) to ensure consistent encoding.
  - All files are saved in UTF-8 (without BOM) to avoid encoding issues.

---

## Requirements

- **Operating System:** Windows 10/11, macOS, or Linux (with PowerShell Core installed)
- **Tools:**
  - PowerShell (built-in on Windows; install PowerShell Core on macOS/Linux)
  - [`ollama.exe`](https://ollama.com/) must be installed and included in your system PATH.
- **Internet Access:** Needed for fetching model data from the Ollama Library.

---

## Installation

1. **Clone the Repository:**

   ```bash
   git clone <repository_url>
   cd <repository_directory>
