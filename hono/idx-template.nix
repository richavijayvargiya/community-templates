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
    
    # Overwrite src/index.ts with content that correctly handles port assignment
    cat > "$WS_NAME/src/index.ts" << 'EOF'
import { serve } from '@hono/node-server'
import { Hono } from 'hono'

const app = new Hono()

app.get('/', (c) => {
  return c.text('Hello Hono!')
})

const portArgIndex = process.argv.indexOf('--port')
#let port = 3000;
#if (portArgIndex !== -1) {
#  port = parseInt(process.argv[portArgIndex + 1])
#} else if (process.env.PORT) {
 # port = parseInt(process.env.PORT)
#}
const portIndex = process.argv.indexOf('--port');
const port = portIndex > -1 ? parseInt(process.argv[portIndex + 1], 10) : 3000;

serve({
  fetch: app.fetch,
  port: port
}, (info) => {
  console.log(`Server is running on http://localhost:\${info.port}`)
})
EOF

    mv "$WS_NAME" "$out"
    cd "$out"; npm install --package-lock-only --ignore-scripts
  '';
}
