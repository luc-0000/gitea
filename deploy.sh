#!/bin/bash
# Gitea ECS部署脚本
# 目标服务器：Ubuntu 24.04 @ 8.155.165.237

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Gitea ECS 部署脚本${NC}"
echo -e "${GREEN}========================================${NC}"

# 服务器配置
SERVER_IP="8.155.165.237"
SERVER_USER="root"  # 如果不是root，改为你的用户名
DEPLOY_PATH="/opt/gitea"

echo -e "\n${YELLOW}1. 检查本地文件...${NC}"
if [ ! -f "docker-compose.prod.yml" ]; then
    echo -e "${RED}错误：找不到 docker-compose.prod.yml${NC}"
    exit 1
fi

if [ ! -d "custom/conf" ]; then
    echo -e "${RED}错误：找不到 custom/conf 目录${NC}"
    exit 1
fi

echo -e "${GREEN}✓ 本地文件检查通过${NC}"

# 询问是否继续
echo -e "\n${YELLOW}2. 准备部署到 ${SERVER_IP}${NC}"
echo -e "部署目录：${DEPLOY_PATH}"
echo -e "将上传："
echo -e "  - docker-compose.prod.yml"
echo -e "  - custom/conf/app.ini"
read -p "确认继续？(y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}部署已取消${NC}"
    exit 0
fi

echo -e "\n${YELLOW}3. 创建部署脚本...${NC}"

# 生成远程脚本
cat > deploy-remote.sh << 'EOF'
#!/bin/bash
set -e

echo "开始部署..."

# 创建部署目录
sudo mkdir -p /opt/gitea
cd /opt/gitea

# 检查Docker
if ! command -v docker &> /dev/null; then
    echo "Docker未安装，正在安装..."
    # 更新包索引
    sudo apt-get update

    # 安装Docker
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh

    # 启动Docker
    sudo systemctl start docker
    sudo systemctl enable docker

    # 添加当前用户到docker组
    sudo usermod -aG docker $USER

    echo "Docker安装完成"
fi

# 检查Docker Compose
if ! command -v docker compose &> /dev/null; then
    echo "Docker Compose未安装，正在安装..."
    sudo apt-get update
    sudo apt-get install -y docker-compose-plugin
    echo "Docker Compose安装完成"
fi

echo "Docker环境检查完成"
docker --version
docker compose version

# 停止现有容器（如果存在）
if [ -f "docker-compose.yml" ]; then
    echo "停止现有容器..."
    docker compose down
fi

# 备份现有配置
if [ -f "custom/conf/app.ini" ]; then
    echo "备份现有配置..."
    cp custom/conf/app.ini custom/conf/app.ini.backup.$(date +%Y%m%d_%H%M%S)
fi

echo "部署完成！"
echo ""
echo "======================================"
echo "部署脚本已执行完成"
echo "======================================"
EOF

echo -e "${GREEN}✓ 部署脚本创建完成${NC}"

echo -e "\n${YELLOW}4. 上传文件到服务器...${NC}"
echo -e "${YELLOW}请手动执行以下命令：${NC}"
echo ""
echo -e "# 1. 上传部署脚本"
echo "scp deploy-remote.sh ${SERVER_USER}@${SERVER_IP}:/tmp/"
echo ""
echo -e "# 2. 上传配置文件"
echo "ssh ${SERVER_USER}@${SERVER_IP} 'mkdir -p ${DEPLOY_PATH}/custom/conf'"
echo "scp docker-compose.prod.yml ${SERVER_USER}@${SERVER_IP}:${DEPLOY_PATH}/docker-compose.yml"
echo "scp custom/conf/app.ini ${SERVER_USER}@${SERVER_IP}:${DEPLOY_PATH}/custom/conf/"
echo ""
echo -e "# 3. 执行远程部署"
echo "ssh ${SERVER_USER}@${SERVER_IP} 'bash /tmp/deploy-remote.sh'"
echo ""
echo -e "# 4. 启动Gitea"
echo "ssh ${SERVER_USER}@${SERVER_IP} 'cd ${DEPLOY_PATH} && docker compose up -d'"
echo ""
echo -e "# 5. 检查状态"
echo "ssh ${SERVER_USER}@${SERVER_IP} 'cd ${DEPLOY_PATH} && docker compose ps'"
echo "ssh ${SERVER_USER}@${SERVER_IP} 'cd ${DEPLOY_PATH} && docker compose logs -f'"
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  部署准备完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}下一步操作：${NC}"
echo -e "1. 确保你能SSH登录到 ${SERVER_IP}"
echo -e "2. 执行上面显示的上传命令"
echo -e "3. 在阿里云控制台开放端口：3000 (Web) 和 2222 (SSH)"
echo -e "4. 访问测试：http://${SERVER_IP}:3000/gitea/"
echo ""