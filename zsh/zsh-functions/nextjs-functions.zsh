# ----------------------------------------
# File: nextjs-functions.zsh
# Description: Next.js functions
# ----------------------------------------

# mkroute
# ----------------------------------------
# Creates default folder structure for a Next.js App Router route.
# Supports nested paths like `app/(admin)/dashboard`.
#
# Usage:
#   mkroute [path/to/route]
#
# Example:
#   mkroute app/(admin)/styleguide/typography
#
# Outcome:
#   app/(admin)/styleguide/typography/
#   ├── _components/
#   ├── _contexts/
#   ├── _data/
#   ├── _hooks/
#   └── _types/
# ----------------------------------------

function mkroute() {
  if [ -z "$1" ]; then
    echo "Usage: mkroute [path/to/route]"
    return 1
  fi

  local base_dir="$1"

  # Create full route path and default subfolders
  mkdir -p "$base_dir"/{_components,_contexts,_data,_hooks,_types}

  echo "Created route structure in: $base_dir/"
}
