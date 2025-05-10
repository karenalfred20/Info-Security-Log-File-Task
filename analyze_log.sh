#!/bin/bash

LOG_FILE="access_log"

echo "===== LOG FILE ANALYSIS ====="

# 1. Total, GET, POST requests
total=$(wc -l < "$LOG_FILE")
get=$(grep '"GET' "$LOG_FILE" | wc -l)
post=$(grep '"POST' "$LOG_FILE" | wc -l)
echo -e "\n[1] Request Counts"
echo "Total Requests: $total"
echo "GET Requests: $get"
echo "POST Requests: $post"

# 2. Unique IP Addresses + GET/POST per IP
echo -e "\n[2] Unique IPs"
unique_ips=$(cut -d' ' -f1 "$LOG_FILE" | sort | uniq | wc -l)
echo "Total Unique IPs: $unique_ips"

echo -e "\n[2b] GET and POST Count per IP (Top 10)"
awk '{ip=$1; method=$6} method ~ /"GET|POST/ {count[ip][method]++}
     END {for (ip in count) print ip, "GET:", count[ip]["\"GET"], "POST:", count[ip]["\"POST"]}' "$LOG_FILE" | sort -k3 -nr | head -10

# 3. Failure Requests (4xx or 5xx)
echo -e "\n[3] Failure Requests"
failures=$(awk '$9 ~ /^[45]/' "$LOG_FILE" | wc -l)
fail_percent=$(awk -v t=$total -v f=$failures 'BEGIN { printf("%.2f", (f/t)*100) }')
echo "Total Failures: $failures"
echo "Failure Rate: $fail_percent%"

# 4. Most Active IP
echo -e "\n[4] Most Active IP"
cut -d' ' -f1 "$LOG_FILE" | sort | uniq -c | sort -nr | head -1

# 5. Requests per Hour
echo -e "\n[5] Requests per Hour"
awk -F'[:[]' '{print $3":00"}' "$LOG_FILE" | sort | uniq -c | sort -n | tail -20

# 6. Status Code Breakdown
echo -e "\n[6] Status Code Breakdown"
awk '{print $9}' "$LOG_FILE" | sort | uniq -c | sort -nr

# 7. Most Active User by Method
echo -e "\n[7] Top GET IP"
grep '"GET' "$LOG_FILE" | cut -d' ' -f1 | sort | uniq -c | sort -nr | head -1

echo -e "\n[8] Top POST IP"
grep '"POST' "$LOG_FILE" | cut -d' ' -f1 | sort | uniq -c | sort -nr | head -1

# 8. Daily Request Average
echo -e "\n[9] Daily Request Average"
days=$(awk -F[/:] '{print $2"/"$3"/"$4}' "$LOG_FILE" | sort -u | wc -l)
avg=$(awk -v t=$total -v d=$days 'BEGIN { printf("%.2f", t/d) }')
echo "Total Days: $days"
echo "Average Requests per Day: $avg"

# 9. Days with Most Failures
echo -e "\n[10] Days with Most Failures"
awk '$9 ~ /^[45]/ { split($4, d, ":"); split(d[1], dt, "/"); print dt[1] "/" dt[2] "/" dt[3] }' "$LOG_FILE" | sort | uniq -c | sort -nr | head -5

# 10. Failure Patterns by Hour
echo -e "\n[11] Failure Patterns by Hour"
awk '$9 ~ /^[45]/ {split($4, t, ":"); print t[2]":00"}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -10

# 11. Request Trends (Top 10 Hours)
echo -e "\n[12] Request Trends (Top Hours)"
awk -F'[:[]' '{print $3":00"}' "$LOG_FILE" | sort | uniq -c | sort -nr | head -10

