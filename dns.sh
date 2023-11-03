
#!/bin/bash
# time1=$(date +%s)
 domain="$1"
 CNAME_record=()
log() {
    local message="$1"
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $message"
}

# Initialize arrays
declare -a unique_cnames=()
declare -a unique_mx=()

extract_unique_records() {
    local record_type="$1"
    local -n records="$2" 
    local -n unique_array_name="$3"
    
    for record in "${records[@]}"; do
      

   
       if [ -z  "$(trim "$record")" ]; then 
                 log "No record found " >&2
                continue
        fi
        if [ -n "$record" ]; then
           num_fields=$(echo "$record" | awk -F. '{print NF}')

            if [ "$num_fields" -ge 2 ]; then
                cut_string=$(echo "$record" | awk -F. '{print $(NF-2)"."$(NF-1)}')
            fi
           
            # Check if cut_string is not in the respective unique array
            if [[ ! " ${unique_array_name[@]} " =~ " $cut_string" ]]; then
                
         
                # echo "$cut_string"
                 unique_array_name+=("$cut_string")
           fi
             
        fi
    done
  printf "%s\n" "${unique_array_name[@]}"

  unset -n  unique_array_name

}

  output=($(curl -s "https://crt.sh/?q=%25.$domain&output=json" | grep -oP '\"name_value\":\"\K.*?(?=\")' | sort -u ))
 
# logging


 trim() {
     echo "$1" | xargs
 }
if [ -z  "$(trim "${output[@]}")" ]; then 
    log "Domain $domain does not exist" >&2
     exit 1 
fi

echo "Email tool for $domain:"
unique_mx=()

 mx=$(dig  mx "$domain" 2>/dev/null)
  mx_out=($(echo "$mx" | grep -E 'IN\s+MX' | awk '{print $5, $6, $7}'))

   status=$(echo "$mx" | grep -o 'status: [A-Z]*' | awk '{print $2}')
   query_time=$(echo "$mx" | grep -o 'Query time: [0-9]*' | awk '{print $3}')  
# logging
  if [ $query_time -eq  0 ] ; then
      log "Error fetching MX records for $domain"
  fi

if [ -z "$(trim "${mx_out[@]}")" ]; then 
    log "No email tool were found during scanning"
  
fi

 extract_unique_records "MX" mx_out unique_mx
#   log "function running"

echo "Analytical tool for $domain:"

for subdomain in "${output[@]}"; do

    NAME_record="$(dig cname "$subdomain" 2>/dev/null)"
    
    CNAME_record+=($(echo "$NAME_record" | awk '/^;; ANSWER SECTION:/{getline; print}' | awk '{print $5}'))
    status=$(echo "$NAME_record" | grep -o 'status: [A-Z]*' | awk '{print $2}')
    query_time=$(echo "$NAME_record" | grep -o 'Query time: [0-9]*' | awk '{print $3}')  
# logging

    if [ "$status" = "SERVFAIL" ]; then
         log "Error fetching MX records for $domain"
   fi
 
done
#   logging
if [ -z "$(trim "${CNAME_record[@]}")" ]; then 
    log "No  analatycal tool were found during scanning"
  
fi

    extract_unique_records "CNAME" CNAME_record unique_cnames
    unset unique_cnames


