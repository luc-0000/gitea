# Gitea ECS 部署指南

## 服务器信息
- **公网IP**: 8.155.165.237
- **系统**: Ubuntu 24.04 64位
- **部署路径**: /opt/gitea

## 部署架构
```
ECS (8.155.165.237):
  └─ Gitea Docker容器
     ├─ Web: 3000端口
     └─ SSH: 2222端口

本地/其他服务器:
  ├─ 前端
  ├─ 后端
  └─ Nginx (fintools.conf)
```

## 部署步骤

### 1. 准备本地文件
```bash
cd /Users/lu/development/fintools/gitea
chmod +x deploy.sh
./deploy.sh
```

### 2. 手动部署（推荐）

#### 2.1 SSH登录到ECS
```bash
ssh root@8.155.165.237
# 或使用你的用户名
```

#### 2.2 安装Docker（如果未安装）
```bash
# 更新包索引
sudo apt-get update

# 安装Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 启动Docker
sudo systemctl start docker
sudo systemctl enable docker

# 检查版本
docker --version
docker compose version
```

#### 2.3 创建部署目录并上传文件
```bash
# 在本地执行
ssh root@8.155.165.237 'mkdir -p /opt/gitea/custom/conf'

# 上传配置文件
scp docker-compose.prod.yml root@8.155.165.237:/opt/gitea/docker-compose.yml
scp custom/conf/app.ini root@8.155.165.237:/opt/gitea/custom/conf/
```

#### 2.4 启动Gitea
```bash
# 在ECS上执行
cd /opt/gitea
docker compose up -d
```

#### 2.5 检查运行状态
```bash
# 查看容器状态
docker compose ps

# 查看日志
docker compose logs -f gitea
```

### 3. 配置阿里云安全组

在阿里云控制台开放以下端口：
- **3000** - Gitea Web界面
- **2222** - Git SSH

### 4. 测试访问

访问: http://8.155.165.237:3000/gitea/

### 5. 更新本地fintools.conf

修改 `/Users/lu/development/fintools/fintools_project/fintools_backend/nginx/fintools.conf`:

```nginx
upstream gitea_server {
-   server 127.0.0.1:3000;
+   server 8.155.165.237:3000;
}
```

然后重启Nginx：
```bash
sudo nginx -t
sudo nginx -s reload
```

## 常用命令

### 在ECS上管理Gitea

```bash
# 查看状态
cd /opt/gitea
docker compose ps

# 查看日志
docker compose logs -f gitea

# 重启
docker compose restart

# 停止
docker compose down

# 更新Gitea
docker compose pull
docker compose up -d
```

### 备份

```bash
# 备份数据
tar -czf gitea-backup-$(date +%Y%m%d).tar.gz /opt/gitea/data/

# 备份数据库
mysqldump -h rm-bp13i603ewc5ec6t30o.mysql.rds.aliyuncs.com \
  -u fintools -p123Password gitea > gitea-db-backup-$(date +%Y%m%d).sql
```

## 故障排查

### Gitea无法访问
1. 检查容器状态: `docker compose ps`
2. 检查端口是否开放: 阿里云安全组
3. 查看日志: `docker compose logs gitea`

### 数据库连接失败
1. 检查RDS白名单是否包含ECS内网IP
2. 测试连接: `mysql -h rm-bp13i603ewc5ec6t30o.mysql.rds.aliyuncs.com -u fintools -p`

### 502错误
1. 检查容器是否正常运行
2. 查看Gitea日志确认是否启动成功
3. 检查数据库migration版本是否匹配

## 配置文件说明

- `docker-compose.yml` - Docker Compose配置
- `custom/conf/app.ini` - Gitea主配置文件
  - DOMAIN: 8.155.165.237
  - ROOT_URL: http://8.155.165.237:3000/gitea/
  - 数据库: RDS MySQL

## 注意事项

1. ⚠️ 生产环境建议配置HTTPS
2. ⚠️ 定期备份data目录和数据库
3. ⚠️ 修改默认密码
4. ⚠️ 配置防火墙规则