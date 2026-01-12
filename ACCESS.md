# Easy Access Guide - Get Started in 5 Minutes

**Choose your path based on how quickly you want to get started:**

| Method | Time | Best For | Cost |
|--------|------|----------|------|
| 🖥️ **[Local](#-fastest-way-run-locally-2-minutes)** | 2 min | Testing, development | FREE |
| ☁️ **[Cloud VM](#option-b-deploy-to-your-own-vm-10-minutes)** | 5 min | Production, custom setup | $25-30/mo |
| 🚀 **[One-Click](#option-a-one-click-cloud-deployment-recommended)** | 5 min | Easy production | $5/mo free tier |

---

## 🚀 Fastest Way: Run Locally (2 minutes)

If you have Docker installed on your computer:

```bash
# Clone the repo
git clone https://github.com/Fosowl/agenticSeek.git
cd agenticSeek

# Copy environment file
cp .env.example .env

# Start everything
./start_services.sh full  # On Mac/Linux
# OR
start_services.cmd full   # On Windows

# Wait 2-3 minutes for all services to start
# Then open: http://localhost:3000
```

That's it! The app will be running at **http://localhost:3000**

---

## ☁️ Deploy to Cloud (5-10 minutes)

### Option A: One-Click Cloud Deployment (Recommended)

We support easy deployment to several platforms:

#### **Railway.app** (Easiest - Free Tier Available)

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.app/template/agenticseeek)

1. Click the button above (or visit https://railway.app)
2. Sign in with GitHub
3. Click "Deploy Now"
4. Wait 3-5 minutes for deployment
5. Access your app at the provided Railway URL

**Cost**: Free tier includes $5/month credit (sufficient for testing)

#### **Render.com** (Easy - Free Tier Available)

1. Go to https://render.com
2. Sign in with GitHub
3. Click "New +" → "Blueprint"
4. Connect your forked AgenticSeek repo
5. Click "Apply"
6. Access your app at `https://your-app.onrender.com`

**Cost**: Free tier available (may spin down after inactivity)

---

### Option B: Deploy to Your Own VM (10 minutes)

For more control, deploy to any cloud VM:

#### Quick Deploy Script

```bash
# 1. Create a VM on any cloud provider:
#    - AWS EC2, Google Cloud, Azure, DigitalOcean, etc.
#    - Size: 4GB RAM minimum (t3.medium on AWS)
#    - OS: Ubuntu 22.04

# 2. SSH into your VM and run this one-liner:
curl -fsSL https://raw.githubusercontent.com/Fosowl/agenticSeek/main/scripts/quick-deploy.sh | bash

# 3. Follow the prompts to configure
# 4. Access at: http://YOUR_VM_IP:3000
```

**Manual deployment**: See [DEPLOYMENT.md](./DEPLOYMENT.md) for detailed instructions.

---

## 🔧 Configuration

### Required Environment Variables

The app works out-of-the-box for local deployment. For cloud deployment, you may want to configure:

```bash
# Optional: Add your API keys for cloud LLM providers
OPENAI_API_KEY=sk-...        # For GPT models
DEEPSEEK_API_KEY=...         # For Deepseek models
GOOGLE_API_KEY=...           # For Gemini models

# Optional: Customize ports
FRONTEND_PORT=3000           # Web interface port
BACKEND_PORT=7777            # API port
```

### For Local LLM (Recommended for Privacy)

If you have a GPU and want to run models locally:

```bash
# Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# Pull a model
ollama pull deepseek-r1:14b

# Start Ollama
ollama serve

# Update config.ini to use ollama
```

---

## 📱 Accessing the Application

Once deployed, you'll see:

### **Simple Chat Interface** (Default)
- Clean ChatGPT-like interface
- Just type and chat!
- Perfect for everyday use

### **Advanced Mode**
- Click "🔧 Advanced" in the top-right
- See real-time code editing
- Watch browser automation
- Monitor agent activities

---

## 🆘 Quick Troubleshooting

### "Can't access the app"
- **Local**: Make sure Docker is running (`docker ps`)
- **Cloud**: Check firewall allows ports 3000 and 7777

### "System offline" message
- Wait 2-3 minutes after starting (backend takes time to initialize)
- Check logs: `docker-compose logs backend`

### "Need API keys"
- For local use: No API keys needed! Use Ollama with local models
- For cloud LLMs: Add API keys to `.env` file

---

## 💰 Cost Estimates

### Free Options
- **Local**: Completely free (uses your computer)
- **Railway.app**: $5/month free credit (enough for testing)
- **Render.com**: Free tier available

### Paid Options
- **AWS EC2 t3.medium**: ~$30/month
- **Google Cloud e2-medium**: ~$25/month
- **DigitalOcean 4GB Droplet**: ~$24/month

---

## 📚 Next Steps

1. **Read the [Interface Guide](./docs/INTERFACE.md)** to learn about Simple vs Advanced modes
2. **Try example prompts** shown on the welcome screen
3. **Configure your LLM** - see [README.md](./README.md) for LLM setup
4. **For production deployment** - see [DEPLOYMENT.md](./DEPLOYMENT.md)

---

## 🤝 Need Help?

- 💬 **Discord**: https://discord.gg/8hGDaME3TC
- 🐛 **Issues**: https://github.com/Fosowl/agenticSeek/issues
- 📖 **Full Docs**: [README.md](./README.md)

---

**TL;DR**: 
- **Local**: `./start_services.sh full` then visit `http://localhost:3000`
- **Cloud**: Use Railway.app one-click deploy or run the quick-deploy script on any VM
