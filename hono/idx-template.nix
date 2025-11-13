
/*
 Copyright 2024 Google LLC

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

      https://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

/*
idx-template \
--output-dir /home/user/idx/hono-test \
-a '{ "manager": "bun" }' \
--workspace-name 'app' \
/home/user/idx/hono \
--failure-report
*/
{ pkgs, manager ? "npm", ... }: {
  packages = [
    pkgs.nodejs_20
    pkgs.bun
  ];
  bootstrap = ''
    ${
      if manager == "npm" then "npm create hono@latest \"$WS_NAME\" -- --template nodejs --pm npm --install"
      else if manager == "bun" then "bun create hono@latest \"$WS_NAME\" --template nodejs --pm bun --install"
      else "npm create hono@latest \"$WS_NAME\" -- --template nodejs --pm npm --install"
    }

    mkdir -p "$WS_NAME/.idx/"
    cp -rf ${./dev.nix} "$WS_NAME/.idx/dev.nix"
    chmod -R +w "$WS_NAME"

    file="$WS_NAME/src/index.ts"

    # Inject a resolvePort helper above the default port line (only once).
    # This supports: environment PORT, "--port 9002", and "--port=9002".
    sed -i '/const port = 3000/i \
function resolvePort(defaultPort = 9002): number {\
  const fromEnv = process.env.PORT;\
  if (fromEnv && !Number.isNaN(Number(fromEnv))) {\
    return Number(fromEnv);\
  }\
  const argv = process.argv.slice(2);\
  for (let i = 0; i < argv.length; i++) {\
    const arg = argv[i];\
    if (arg === "--port" && argv[i + 1] && !Number.isNaN(Number(argv[i + 1]))) {\
      return Number(argv[i + 1]);\
    }\
    if (arg.startsWith("--port=")) {\
      const val = arg.split("=")[1];\
      if (val && !Number.isNaN(Number(val))) {\
        return Number(val);\
      }\
    }\
  }\
  return defaultPort;\
}\
' "$file"

    # Replace the original "const port = 3000" with "const port = resolvePort(9002)"
    sed -i 's/const port = 3000/const port = resolvePort(9002)/g' "$file"

    mv "$WS_NAME" "$out"
    cd "$out"; npm install --package-lock-only --ignore-scripts
  '';
}
