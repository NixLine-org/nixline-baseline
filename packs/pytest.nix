{ pkgs, lib }:

#
# $PACK_NAME PACK
#
# This pack provides $PACK_NAME configuration for all repositories that enable it.
#
# To enable this pack in a consumer repository:
# 1. Add "$PACK_NAME" to the persistentPacks list in flake.nix
# 2. Run 'nix run .#sync' to materialize the configuration files
# 3. Commit the generated files to your repository
#

{
  files = {
    "pytest.ini" = ''
      [tool:pytest]
      # Test discovery
      testpaths = tests
      python_files = test_*.py *_test.py
      python_classes = Test*
      python_functions = test_*

      # Output options
      addopts =
          --strict-markers
          --strict-config
          --verbose
          --tb=short
          --cov-report=term-missing
          --cov-report=html
          --cov-fail-under=80

      # Markers
      markers =
          slow: marks tests as slow (deselect with '-m "not slow"')
          integration: marks tests as integration tests
          unit: marks tests as unit tests

      # Filters
      filterwarnings =
          error
          ignore::UserWarning
          ignore::DeprecationWarning

      # Directories to ignore
      norecursedirs =
          .git
          .tox
          dist
          build
          *.egg
          .venv
          venv
    '';
  };

  checks = [
    {
      name = "pytest-config";
      check = ''
        if [[ -f "pytest.ini" ]]; then
          echo "[+] pytest configuration found"
          # Validate pytest config if pytest is available
          if command -v pytest >/dev/null 2>&1; then
            # Test pytest can parse the config
            pytest --version >/dev/null 2>&1 && echo "[+] pytest config is valid"
          fi
        else
          echo "[-] pytest.ini configuration missing"
          exit 1
        fi
      '';
    }
  ];
}
