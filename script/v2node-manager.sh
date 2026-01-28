#!/usr/bin/env bash
set -e
set -u
# Thử kích hoạt pipefail (nếu hỗ trợ)
if (set -o pipefail 2>/dev/null); then
  set -o pipefail
fi

# Đường dẫn tệp cấu hình V2Node
CONFIG_FILE="/etc/v2node/config.json"

# Màu sắc kiểu dáng
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
CYAN='\033[36m'
GRAY='\033[90m'
BOLD='\033[1m'
RESET='\033[0m'

# Kiểm tra jq đã cài đặt chưa
check_jq() {
  if ! command -v jq &> /dev/null; then
    echo -e "${RED}Lỗi: jq chưa được cài đặt${RESET}"
    echo -e "${YELLOW}Đang cài đặt jq...${RESET}"
    if command -v apt-get &> /dev/null; then
      sudo apt-get update && sudo apt-get install -y jq
    elif command -v yum &> /dev/null; then
      sudo yum install -y jq
    else
      echo -e "${RED}Không thể tự động cài đặt jq, vui lòng cài đặt thủ công${RESET}"
      exit 1
    fi
  fi
}

# Kiểm tra tồn tại tệp cấu hình
check_config() {
  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo -e "${RED}Tệp cấu hình không tồn tại: $CONFIG_FILE${RESET}"
    echo -e "${YELLOW}Đang tạo tệp cấu hình mặc định...${RESET}"
    sudo mkdir -p "$(dirname "$CONFIG_FILE")"
    sudo tee "$CONFIG_FILE" > /dev/null <<EOF
{
    "Log": {
        "Level": "warning",
        "Output": "",
        "Access": "none"
    },
    "Nodes": []
}
EOF
    echo -e "${GREEN}Đã tạo tệp cấu hình mặc định${RESET}"
  fi
}

# Khởi động lại dịch vụ v2node
restart_v2node() {
  echo ""
  echo -e "${YELLOW}Đang khởi động lại dịch vụ v2node...${RESET}"
  
  # 尝试使用 systemctl
  if command -v systemctl >/dev/null 2>&1; then
    if systemctl list-units --type=service --all | grep -q "v2node"; then
      if sudo systemctl restart v2node 2>/dev/null; then
        echo -e "${GREEN}v2node 服务已重启${RESET}"
        return 0
      fi
    fi
  fi
  
  # 尝试使用 service 命令
  if command -v service >/dev/null 2>&1; then
    if sudo service v2node restart 2>/dev/null; then
      echo -e "${GREEN}v2node 服务已重启${RESET}"
      return 0
    fi
  fi
  
  # Nếu tất cả thất bại, nhắc khởi động lại thủ công
  echo -e "${YELLOW}Không thể tự động khởi động lại dịch vụ v2node, vui lòng khởi động lại thủ công${RESET}"
  echo -e "${GRAY}Có thể thử: systemctl restart v2node hoặc service v2node restart${RESET}"
}

# Liệt kê tất cả các node
list_nodes() {
  echo -e "${BOLD}${CYAN}Danh sách node hiện tại:${RESET}"
  echo ""
  
  local node_count=$(sudo jq '.Nodes | length' "$CONFIG_FILE")
  
  if [[ "$node_count" -eq 0 ]]; then
    echo -e "${YELLOW}Chưa có node nào${RESET}"
    return
  fi
  
  echo -e "${GRAY}Tổng $node_count node${RESET}"
  echo ""
  
  # Sử dụng jq để định dạng đầu ra
  sudo jq -r '.Nodes | to_entries | .[] | 
    "Node #\(.key + 1)\n" +
    "  NodeID: \(.value.NodeID)\n" +
    "  ApiHost: \(.value.ApiHost)\n" +
    "  ApiKey: \(.value.ApiKey)\n" +
    "  Timeout: \(.value.Timeout)\n"' "$CONFIG_FILE"
}

# Xóa node
delete_node() {
  list_nodes
  echo ""
  
  local node_count=$(sudo jq '.Nodes | length' "$CONFIG_FILE")
  if [[ "$node_count" -eq 0 ]]; then
    echo -e "${YELLOW}Không có node nào để xóa${RESET}"
    return
  fi
  
  echo -en "${BOLD}Nhập số thứ tự node hoặc NodeID cần xóa (1-$node_count hoặc NodeID, hỗ trợ đơn lẻ, phạm vi hoặc phân tách bằng dấu phẩy, ví dụ 1,3,5 hoặc 1-5 hoặc 96-98): ${RESET}"
  read -r input
  
  if [[ -z "$input" ]]; then
    echo -e "${RED}Hủy thao tác${RESET}"
    return
  fi
  
  # Lấy danh sách tất cả NodeID (để xóa thông qua NodeID)
  local nodeid_list=()
  local nodeid_to_index=()
  local index=0
  while IFS= read -r nodeid; do
    nodeid_list+=("$nodeid")
    nodeid_to_index["$nodeid"]=$index
    index=$((index + 1))
  done < <(sudo jq -r '.Nodes[].NodeID' "$CONFIG_FILE")
  
  # Phân tích đầu vào (hỗ trợ nhiều số phân tách bằng dấu phẩy và phạm vi)
  local all_numbers=()
  IFS=',' read -ra parts <<< "$input"
  
  # Xử lý từng phần (có thể là số đơn lẻ hoặc phạm vi)
  for part in "${parts[@]}"; do
    part=$(echo "$part" | tr -d ' ')
    if [[ -z "$part" ]]; then
      continue
    fi
    
    # Thử phân tích thành phạm vi hoặc số đơn lẻ
    # Trước hết kiểm tra có phải là số nguyên thuần không (đơn lẻ)
    if [[ "$part" =~ ^[0-9]+$ ]]; then
      all_numbers+=("$part")
    # Kiểm tra xem có phải là định dạng phạm vi không
    elif [[ "$part" =~ ^[0-9]+-[0-9]+$ ]]; then
      local start=$(echo "$part" | cut -d'-' -f1)
      local end=$(echo "$part" | cut -d'-' -f2)
      
      if [[ "$start" -le "$end" ]]; then
        for ((i=start; i<=end; i++)); do
          all_numbers+=("$i")
        done
      else
        echo -e "${RED}Lỗi phạm vi: giá trị bắt đầu phải nhỏ hơn hoặc bằng giá trị kết thúc ($part)${RESET}"
        return
      fi
    else
      echo -e "${RED}Định dạng đầu vào không hợp lệ: $part (vui lòng nhập số hoặc phạm vi, ví dụ 96 hoặc 96-98)${RESET}"
      return
    fi
  done
  
  if [[ ${#all_numbers[@]} -eq 0 ]]; then
    echo -e "${RED}Không có đầu vào hợp lệ${RESET}"
    return
  fi
  
  # Phán đoán là số thứ tự node hay NodeID, và chuyển đổi thành chỉ số mảng
  local delete_indices=()
  declare -A seen
  
  for num in "${all_numbers[@]}"; do
    # Trước tiên thử làm số thứ tự node (1 đến node_count)
    if [[ "$num" -ge 1 ]] && [[ "$num" -le "$node_count" ]]; then
      local idx=$((num - 1))
      if [[ -z "${seen[$idx]:-}" ]]; then
        seen[$idx]=1
        delete_indices+=($idx)
      fi
    else
      # Nếu không phải số thứ tự node, thử làm NodeID
      local found=false
      for i in "${!nodeid_list[@]}"; do
        if [[ "${nodeid_list[$i]}" == "$num" ]]; then
          if [[ -z "${seen[$i]:-}" ]]; then
            seen[$i]=1
            delete_indices+=($i)
            found=true
          fi
          break
        fi
      done
      
      if [[ "$found" == "false" ]]; then
        echo -e "${YELLOW}Cảnh báo: Không tìm thấy NodeID $num, bỏ qua${RESET}"
      fi
    fi
  done
  
  if [[ ${#delete_indices[@]} -eq 0 ]]; then
    echo -e "${RED}Không tìm thấy node cần xóa${RESET}"
    return
  fi
  
  # Sắp xếp (từ lớn đến nhỏ, tránh chỉ số thay đổi sau khi xóa)
  IFS=$'\n' delete_indices=($(printf '%s\n' "${delete_indices[@]}" | sort -rn))
  
  # Xóa node (xóa từ sau ra trước, tránh chỉ số thay đổi)
  local temp_file=$(mktemp)
  sudo cp "$CONFIG_FILE" "$temp_file"
  
  for idx in "${delete_indices[@]}"; do
    sudo jq "del(.Nodes[$idx])" "$temp_file" > "${temp_file}.new"
    mv "${temp_file}.new" "$temp_file"
  done
  
  sudo mv "$temp_file" "$CONFIG_FILE"
  sudo chmod 644 "$CONFIG_FILE"
  
  echo -e "${GREEN}Đã xóa ${#delete_indices[@]} node${RESET}"
  
  # Khởi động lại dịch vụ v2node
  restart_v2node
}

# Phân tích đầu vào phạm vi (ví dụ 1-5)
parse_range() {
  local input="$1"
  local result=()
  
  if [[ "$input" =~ ^[0-9]+-[0-9]+$ ]]; then
    local start=$(echo "$input" | cut -d'-' -f1)
    local end=$(echo "$input" | cut -d'-' -f2)
    
    if [[ "$start" -le "$end" ]]; then
      for ((i=start; i<=end; i++)); do
        result+=($i)
      done
    else
      echo -e "${RED}Lỗi phạm vi: giá trị bắt đầu phải nhỏ hơn hoặc bằng giá trị kết thúc${RESET}" >&2
      return 1
    fi
  elif [[ "$input" =~ ^[0-9]+$ ]]; then
    result+=($input)
  else
    echo -e "${RED}Lỗi định dạng: vui lòng nhập số hoặc phạm vi (ví dụ 1-5)${RESET}" >&2
    return 1
  fi
  
  echo "${result[@]}"
}

# Thêm node
add_node() {
  echo -e "${BOLD}${CYAN}Thêm node mới${RESET}"
  echo ""
  
  local node_count=$(sudo jq '.Nodes | length' "$CONFIG_FILE")
  local api_host=""
  local api_key=""
  local timeout=15
  
  # Nếu có node hiện có, hỏi có muốn dùng lại không
  if [[ "$node_count" -gt 0 ]]; then
    echo -e "${BOLD}Có dùng lại ApiHost và ApiKey của node hiện có không?${RESET}"
    echo -e "  ${YELLOW}1)${RESET} Có, chọn node hiện có"
    echo -e "  ${YELLOW}2)${RESET} Không, nhập thủ công"
    echo -en "${BOLD}Lựa chọn của bạn (mặc định: 2): ${RESET}"
    read -r use_existing
    
    if [[ "$use_existing" == "1" ]]; then
      # Liệt kê tất cả node để chọn
      echo ""
      echo -e "${BOLD}${CYAN}Vui lòng chọn node cần dùng lại:${RESET}"
      echo ""
      
      # Hiển thị danh sách node
      local index=0
      while IFS=$'\t' read -r nodeid host key; do
        index=$((index + 1))
        echo -e "  ${YELLOW}$index)${RESET} NodeID: $nodeid, ApiHost: $host"
      done < <(sudo jq -r '.Nodes[] | "\(.NodeID)\t\(.ApiHost)\t\(.ApiKey)"' "$CONFIG_FILE")
      
      echo ""
      echo -en "${BOLD}Nhập số thứ tự node (1-$node_count): ${RESET}"
      read -r selected_index
      
      if [[ -z "$selected_index" ]] || ! [[ "$selected_index" =~ ^[0-9]+$ ]] || [[ "$selected_index" -lt 1 ]] || [[ "$selected_index" -gt "$node_count" ]]; then
        echo -e "${RED}Số thứ tự node không hợp lệ, hủy thao tác${RESET}"
        return
      fi
      
      local array_index=$((selected_index - 1))
      api_host=$(sudo jq -r ".Nodes[$array_index].ApiHost" "$CONFIG_FILE")
      api_key=$(sudo jq -r ".Nodes[$array_index].ApiKey" "$CONFIG_FILE")
      timeout=$(sudo jq -r ".Nodes[$array_index].Timeout" "$CONFIG_FILE")
      
      echo ""
      echo -e "${GREEN}Đã chọn cấu hình node:${RESET}"
      echo -e "  ${GRAY}ApiHost: $api_host${RESET}"
      echo -e "  ${GRAY}ApiKey: $api_key${RESET}"
      echo -e "  ${GRAY}Timeout: $timeout${RESET}"
      echo ""
    else
      # Nhập cấu hình thủ công
      echo ""
      echo -en "${BOLD}API Host: ${RESET}"
      read -r api_host
      if [[ -z "$api_host" ]]; then
        echo -e "${RED}API Host không được để trống${RESET}"
        return
      fi
      
      echo -en "${BOLD}API Key: ${RESET}"
      read -r api_key
      if [[ -z "$api_key" ]]; then
        echo -e "${RED}API Key không được để trống${RESET}"
        return
      fi
      
      echo -en "${BOLD}Timeout (mặc định: 15): ${RESET}"
      read -r timeout_input
      timeout=${timeout_input:-15}
    fi
  else
    # Không có node hiện có, phải nhập thủ công
    echo -en "${BOLD}API Host: ${RESET}"
    read -r api_host
    if [[ -z "$api_host" ]]; then
      echo -e "${RED}API Host không được để trống${RESET}"
      return
    fi
    
    echo -en "${BOLD}API Key: ${RESET}"
    read -r api_key
    if [[ -z "$api_key" ]]; then
      echo -e "${RED}API Key không được để trống${RESET}"
      return
    fi
    
    echo -en "${BOLD}Timeout (mặc định: 15): ${RESET}"
    read -r timeout_input
    timeout=${timeout_input:-15}
  fi
  
  # Nhập NodeID
  echo ""
  echo -en "${BOLD}NodeID (số đơn lẻ, ví dụ 95, hoặc phạm vi, ví dụ 1-5): ${RESET}"
  read -r nodeid_input
  
  if [[ -z "$nodeid_input" ]]; then
    echo -e "${RED}Hủy thao tác${RESET}"
    return
  fi
  
  # Phân tích NodeID (hỗ trợ đơn lẻ hoặc phạm vi)
  local nodeids
  if ! nodeids=$(parse_range "$nodeid_input"); then
    return
  fi
  
  # Kiểm tra NodeID có tồn tại chưa
  local existing_nodeids=()
  if [[ "$node_count" -gt 0 ]]; then
    while IFS= read -r nodeid; do
      existing_nodeids+=("$nodeid")
    done < <(sudo jq -r '.Nodes[].NodeID' "$CONFIG_FILE")
  fi
  
  local nodes_to_add=()
  for nodeid in $nodeids; do
    # Kiểm tra đã tồn tại chưa
    local exists=false
    for existing in "${existing_nodeids[@]}"; do
      if [[ "$nodeid" == "$existing" ]]; then
        echo -e "${YELLOW}Cảnh báo: NodeID $nodeid đã tồn tại, sẽ bỏ qua${RESET}"
        exists=true
        break
      fi
    done
    
    if [[ "$exists" == "false" ]]; then
      nodes_to_add+=("$nodeid")
    fi
  done
  
  if [[ ${#nodes_to_add[@]} -eq 0 ]]; then
    echo -e "${RED}Không có node nào để thêm (tất cả NodeID đều đã tồn tại)${RESET}"
    return
  fi
  
  # Thêm node
  local temp_file=$(mktemp)
  sudo cp "$CONFIG_FILE" "$temp_file"
  
  for nodeid in "${nodes_to_add[@]}"; do
    local new_node=$(jq -n \
      --arg api_host "$api_host" \
      --argjson nodeid "$nodeid" \
      --arg api_key "$api_key" \
      --argjson timeout "$timeout" \
      '{
        "ApiHost": $api_host,
        "NodeID": $nodeid,
        "ApiKey": $api_key,
        "Timeout": $timeout
      }')
    
    sudo jq ".Nodes += [$new_node]" "$temp_file" > "${temp_file}.new"
    mv "${temp_file}.new" "$temp_file"
  done
  
  sudo mv "$temp_file" "$CONFIG_FILE"
  sudo chmod 644 "$CONFIG_FILE"
  
  echo ""
  echo -e "${GREEN}Đã thêm ${#nodes_to_add[@]} node${RESET}"
  echo -e "${GRAY}NodeID: ${nodes_to_add[*]}${RESET}"
  echo -e "${GRAY}ApiHost: $api_host${RESET}"
  
  # Khởi động lại dịch vụ v2node
  restart_v2node
}

# Sửa node
edit_node() {
  list_nodes
  echo ""
  
  local node_count=$(sudo jq '.Nodes | length' "$CONFIG_FILE")
  if [[ "$node_count" -eq 0 ]]; then
    echo -e "${YELLOW}Không có node nào để sửa${RESET}"
    return
  fi
  
  echo -en "${BOLD}Nhập số thứ tự node cần sửa (1-$node_count): ${RESET}"
  read -r node_index
  
  if [[ -z "$node_index" ]] || ! [[ "$node_index" =~ ^[0-9]+$ ]] || [[ "$node_index" -lt 1 ]] || [[ "$node_index" -gt "$node_count" ]]; then
    echo -e "${RED}Số thứ tự node không hợp lệ${RESET}"
    return
  fi
  
  local array_index=$((node_index - 1))
  
  # Lấy giá trị hiện tại
  local current_node=$(sudo jq ".Nodes[$array_index]" "$CONFIG_FILE")
  local current_nodeid=$(echo "$current_node" | jq -r '.NodeID')
  local current_api_host=$(echo "$current_node" | jq -r '.ApiHost')
  local current_api_key=$(echo "$current_node" | jq -r '.ApiKey')
  local current_timeout=$(echo "$current_node" | jq -r '.Timeout')
  
  echo ""
  echo -e "${GRAY}Cấu hình hiện tại:${RESET}"
  echo -e "  NodeID: $current_nodeid"
  echo -e "  ApiHost: $current_api_host"
  echo -e "  ApiKey: $current_api_key"
  echo -e "  Timeout: $current_timeout"
  echo ""
  
  # Nhập giá trị mới (Enter giữ nguyên giá trị cũ)
  echo -en "${BOLD}NodeID (mặc định: $current_nodeid): ${RESET}"
  read -r new_nodeid
  new_nodeid=${new_nodeid:-$current_nodeid}
  
  echo -en "${BOLD}API Host (mặc định: $current_api_host): ${RESET}"
  read -r new_api_host
  new_api_host=${new_api_host:-$current_api_host}
  
  echo -en "${BOLD}API Key (mặc định: $current_api_key): ${RESET}"
  read -r new_api_key
  new_api_key=${new_api_key:-$current_api_key}
  
  echo -en "${BOLD}Timeout (mặc định: $current_timeout): ${RESET}"
  read -r new_timeout
  new_timeout=${new_timeout:-$current_timeout}
  
  # Kiểm tra NodeID có xung đột với node khác không
  if [[ "$new_nodeid" != "$current_nodeid" ]]; then
    local existing_nodeids=()
    while IFS= read -r nodeid; do
      if [[ "$nodeid" != "$current_nodeid" ]]; then
        existing_nodeids+=("$nodeid")
      fi
    done < <(sudo jq -r '.Nodes[].NodeID' "$CONFIG_FILE")
    
    for existing in "${existing_nodeids[@]}"; do
      if [[ "$new_nodeid" == "$existing" ]]; then
        echo -e "${RED}Lỗi: NodeID $new_nodeid đã được node khác sử dụng${RESET}"
        return
      fi
    done
  fi
  
  # Cập nhật node
  local temp_file=$(mktemp)
  sudo jq \
    --argjson nodeid "$new_nodeid" \
    --arg api_host "$new_api_host" \
    --arg api_key "$new_api_key" \
    --argjson timeout "$new_timeout" \
    ".Nodes[$array_index] = {
      \"NodeID\": \$nodeid,
      \"ApiHost\": \$api_host,
      \"ApiKey\": \$api_key,
      \"Timeout\": \$timeout
    }" "$CONFIG_FILE" > "$temp_file"
  
  sudo mv "$temp_file" "$CONFIG_FILE"
  sudo chmod 644 "$CONFIG_FILE"
  
  echo -e "${GREEN}Node đã được cập nhật${RESET}"
  
  # Khởi động lại dịch vụ v2node
  restart_v2node
}

# Menu chính
function v2node_menu() {
  while true; do
    echo ""
    echo -e "${BOLD}${CYAN}Quản lý cấu hình V2Node${RESET}"
    echo -e "${GRAY}Tệp cấu hình: $CONFIG_FILE${RESET}"
    echo ""
    echo -e "${BOLD}Vui lòng chọn thao tác cần thực hiện (nhập số và Enter):${RESET}"
    echo -e "  ${YELLOW}1)${RESET} Liệt kê tất cả node"
    echo -e "  ${YELLOW}2)${RESET} Thêm node (${GRAY}hỗ trợ thêm theo phạm vi, ví dụ 1-5${RESET})"
    echo -e "  ${YELLOW}3)${RESET} Xóa node (${GRAY}hỗ trợ xóa theo phạm vi, ví dụ 1-5 hoặc 96-98${RESET})"
    echo -e "  ${YELLOW}4)${RESET} Sửa node"
    echo -e "  ${YELLOW}5)${RESET} Xem nội dung tệp cấu hình"
    echo -e "  ${YELLOW}0)${RESET} Quay về menu chính"
    echo -en "${BOLD}Lựa chọn của bạn:${RESET} "
    
    read -r choice
    
    case "$choice" in
      1) 
        list_nodes
        echo ""
        echo -e "${GREEN}Hoàn tất.${RESET} Bấm Enter để tiếp tục..."
        read -r
        ;;
      2) 
        add_node
        echo ""
        echo -e "${GREEN}Hoàn tất.${RESET} Bấm Enter để tiếp tục..."
        read -r
        ;;
      3) 
        delete_node
        echo ""
        echo -e "${GREEN}Hoàn tất.${RESET} Bấm Enter để tiếp tục..."
        read -r
        ;;
      4) 
        edit_node
        echo ""
        echo -e "${GREEN}Hoàn tất.${RESET} Bấm Enter để tiếp tục..."
        read -r
        ;;
      5) 
        echo ""
        echo -e "${BOLD}${CYAN}Nội dung tệp cấu hình:${RESET}"
        sudo cat "$CONFIG_FILE" | jq .
        echo ""
        echo -e "${GREEN}Hoàn tất.${RESET} Bấm Enter để tiếp tục..."
        read -r
        ;;
      0) 
        return 0
        ;;
      *) 
        echo -e "${RED}Tùy chọn không hợp lệ${RESET}, vui lòng chọn lại"
        sleep 1
        ;;
    esac
  done
}

# Hàm chính
main() {
  # Hiển thị tiêu đề
  echo -e "${BLUE}==============================================${RESET}"
  echo -e "${BOLD}${CYAN} Công cụ quản lý cấu hình V2Node${RESET}"
  echo -e "${GRAY}Tệp cấu hình: $CONFIG_FILE${RESET}"
  echo -e "${BLUE}==============================================${RESET}"
  
  check_jq
  check_config
  v2node_menu
}

# Nếu chạy trực tiếp script này
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main
fi

