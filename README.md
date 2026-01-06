
# Solis (Ginlong) → InfluxDB → Grafana (via SolisCloud/Solarman API)

Production‑ready stack for collecting Solis inverter metrics from the **SolisCloud / Solarman v5** API with **Telegraf only** (no custom app), storing in **InfluxDB 2.x**, and visualising in **Grafana**.

- Telegraf runs an `exec` script (`curl` + `jq`) that **logs in**, fetches **latest** device data, and emits JSON.
- Telegraf parses JSON with `json_v2` and writes to InfluxDB.
- A ready-to-import Grafana dashboard is included.

> ⚠️ **Do not put secrets in Git.** Use **Portainer Secrets** (recommended) or **Environment overrides** when deploying the stack.

---

## Quick start (Portainer → Git-based stack)

1. **Create Secrets** in **Portainer → Secrets** (Docker Swarm Required):
   - `influx_token` — InfluxDB API token (you can set via Influx UI after first boot).
   - `solis_password` — your SolisCloud/Solarman account password.
   - `solarman_client_id` — *(optional, if your tenant requires)*.
   - `solarman_client_secret` — *(optional, if your tenant requires)*.
   - `grafana_admin_password` — *(optional)* Grafana admin password.

2. **Deploy stack** in **Portainer → Stacks → Add stack → Git**:
   - **Repository URL:** https://github.com/Livingdead1989/solis-grafana-stack
   - **Compose path:** `docker-compose.yml`
   - Enable **Build images**
   - In **Environment Variables / Overrides**, set (non-sensitive values):
     - `SOLIS_EMAIL` (e.g., `you@example.com`)
     - `SOLIS_DEVICE_SN` (your datalogger/inverter SN)
     - `SOLIS_POLL_INTERVAL` (e.g., `60`)
     - Optionally: `SOLIS_AUTH_URL`, `SOLIS_LATEST_URL` if your tenant differs  
   - (Optional) For **first-time InfluxDB init**, set:
     - `DOCKER_INFLUXDB_INIT_ADMIN_TOKEN` — a bootstrap token you’ll also store as **`influx_token`** secret for Telegraf.

3. **After deploy**:
   - **InfluxDB** UI: `http://<host>:8086`  
     Org: `home`, Bucket: `solis` (auto-created).  
     If you didn’t set an init admin token, create a token in the UI and update the `influx_token` secret in Portainer.
   - **Grafana** UI: `http://<host>:3000`  
     Login `admin / <password>` (if you set `grafana_admin_password` secret) or default admin (change it!).  
     Add InfluxDB datasource and **import** the dashboard JSON from `grafana/dashboards/solis-cloud-grafana.json`.

4. **Verify data**:
   ```bash
   docker logs telegraf --tail=200
   docker exec -it telegraf /etc/telegraf/scripts/solis_latest.sh | jq .
   ```

---

## Adjusting field mappings

The JSON keys from SolisCloud/Solarman differ by tenant/model.  
Run the script manually:

```bash
docker exec -it telegraf /etc/telegraf/scripts/solis_latest.sh | jq .
```

Then edit `telegraf/telegraf.conf` → `json_v2` `path` values to match your payload.  
Common fields included:
- `active_power`, `grid_voltage`, `grid_frequency`
- `pv1_voltage/current`, `pv2_voltage/current`
- `energy_today`, `energy_total`
- `inverter_temperature`

> Battery models: Add SoC, charge/discharge power, volt/current paths and replicate panels in Grafana.

---

## Security

- **Use Portainer Secrets** for passwords/tokens (Telegraf reads via `/run/secrets/*`).  
- Avoid committing a real `.env` file; this repo provides **`.env.example`** and a **`.gitignore`** that excludes `.env`.

---

## Troubleshooting

- **Enable Docker Swarm**: On the Docker host `docker swarm init`.
- **401 / auth failed**: Check email/password and tenant’s auth requirements (client id/secret).  
- **Empty series in Grafana**: Confirm field names match the API JSON.  
- **Rate limits**: Keep `SOLIS_POLL_INTERVAL` ≥ 30–60s.  
- **Time zones**: Grafana datasource uses server times; adjust dashboard if required.

