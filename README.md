
# Solis (Ginlong) → InfluxDB → Grafana (via SolisCloud/Solarman API)

Production‑ready stack for collecting Solis inverter metrics from the **SolisCloud / Solarman v5** API with **Telegraf only** (no custom app), storing in **InfluxDB 2.x**, and visualising in **Grafana**.

- Telegraf runs an `exec` script (`curl` + `jq`) that **logs in**, fetches **latest** device data, and emits JSON.
- Telegraf parses JSON with `json_v2` and writes to InfluxDB.
- A ready-to-import Grafana dashboard is included.

> ⚠️ **Do not put secrets in Git.** Use **Portainer Secrets** (recommended) or **Environment overrides** when deploying the stack.

---


## ✅ Deploy Steps (Portainer → Git-based stack)

### 1. Prepare Secrets (Recommended)
Create secrets in **Portainer → Secrets**:
- `influx_token` — InfluxDB API token (you’ll create this after InfluxDB starts).
- `solis_password` — your SolisCloud/Solarman account password.
- `solarman_client_id` — *(optional, if your tenant requires)*.
- `solarman_client_secret` — *(optional, if your tenant requires)*.
- `grafana_admin_password` — *(optional)* Grafana admin password.

Alternatively, use **bind-mounted files** under `/opt/solis/secrets` if Portainer Secrets are not available.

---

### 2. Deploy the Stack from Git
1. In **Portainer → Stacks → Add stack → Git**:
   - **Repository URL:** https://github.com/Livingdead1989/solis-grafana-stack
   - **Compose path:** `docker-compose.yml` (or the correct path in your repo).
   - **Branch:** `main` (or your branch).
   - Enable **Build images** (required for custom Telegraf image).
2. In **Environment Variables / Overrides**, set:
   - `SOLIS_EMAIL` (e.g., `you@example.com`)
   - `SOLIS_DEVICE_SN` (your inverter/datalogger serial number)
   - `SOLIS_POLL_INTERVAL` (e.g., `60`)
   - Optionally: `SOLIS_AUTH_URL`, `SOLIS_LATEST_URL` if your tenant differs.
3. Click **Deploy the stack**.

---

### 3. After Deploy: InfluxDB Setup
- Access InfluxDB UI:
  ```
  http://<your-host>:8086
  ```
- Log in with the admin credentials you set in `docker-compose.yml` (default: `admin / admin12345`).
- Go to **Load Data → Tokens → Generate Token**:
  - Choose **All Access Token** or **Read/Write Token** for bucket `solis`.
  - Copy the token and update the `influx_token` secret in Portainer (or your secret file).
- Restart Telegraf:
  ```bash
  docker restart telegraf
  ```

---

### 4. Grafana Setup
- Access Grafana UI:
  ```
  http://<your-host>:3000
  ```
- Log in:
  - Default: `admin / admin` (or the secret you set).
  - Change the password immediately.
- Add **InfluxDB Data Source**:
  - **URL:** `http://influxdb:8086`
  - **Query Language:** Flux
  - **Organisation:** `home`
  - **Bucket:** `solis`
  - **Token:** paste the InfluxDB token you created.
  - Click **Save & Test**.
- Import Dashboard:
  - Go to **Dashboards → New → Import**.
  - Upload `grafana/dashboards/solis-cloud-grafana.json`.
  - Select the InfluxDB data source and click **Import**.

---

### 5. Verify Data Flow
- Check Telegraf logs:
  ```bash
  docker logs telegraf --tail=100
  ```
- Test script manually:
  ```bash
  docker exec -it telegraf /etc/telegraf/scripts/solis_latest.sh | jq .
  ```
- Confirm data in InfluxDB:
  ```bash
  docker exec -it influxdb influx query 'from(bucket:"solis") |> range(start:-5m)'
  ```

---

## Adjusting Field Mappings
Run the script manually:
```bash
docker exec -it telegraf /etc/telegraf/scripts/solis_latest.sh | jq .
```
Update `telegraf/telegraf.conf` → `json_v2` paths to match your API payload.

Common fields:
- `active_power`, `grid_voltage`, `grid_frequency`
- `pv1_voltage/current`, `pv2_voltage/current`
- `energy_today`, `energy_total`
- `inverter_temperature`

> Battery models: Add SoC, charge/discharge power, volt/current paths and replicate panels in Grafana.

---

## Security Best Practices
- Use **Portainer Secrets** or **bind-mounted files** for sensitive values.
- Avoid committing `.env` with real credentials; use `.env.example` for reference.
- Change Grafana admin password immediately after first login.

---

## Troubleshooting

- **Enable Docker Swarm**: On the Docker host `docker swarm init`.
- **401 / auth failed**: Check email/password and tenant’s auth requirements (client id/secret).  
- **Empty series in Grafana**: Confirm field names match the API JSON.  
- **Rate limits**: Keep `SOLIS_POLL_INTERVAL` ≥ 30–60s.  
- **Time zones**: Grafana datasource uses server times; adjust dashboard if required.

