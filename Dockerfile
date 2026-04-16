FROM python:3.12
WORKDIR /app
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl tzdata xvfb x11vnc supervisor xauth \
    fluxbox xterm fonts-wqy-zenhei fonts-wqy-microhei \
    fontconfig && \
    ln -sf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone && \
    fc-cache -fv && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
RUN curl -sSf https://sh.rustup.rs  | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
ENV TZ=Asia/Shanghai
COPY requirements.txt .
RUN python -m pip install --no-cache-dir -r requirements.txt && \
    python -m pip uninstall -y jinja2 && \
    python -m pip install --no-cache-dir "jinja2==3.1.2" "fastapi==0.112.2" "starlette==0.38.6" && \
    python -c "import jinja2, fastapi, starlette; assert jinja2.__version__ == '3.1.2', jinja2.__version__; assert fastapi.__version__ == '0.112.2', fastapi.__version__; assert starlette.__version__ == '0.38.6', starlette.__version__"
COPY . .
RUN apt-get update --allow-unauthenticated && \
    apt-get install -y --allow-unauthenticated --no-install-recommends \
    libnss3 libnspr4 libatk-bridge2.0-0 libdrm2 libxkbcommon0 \
    libgtk-3-0 libgbm1 libasound2 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV BTB_SERVER_NAME="0.0.0.0"
ENV GRADIO_SERVER_PORT=7860
ENV BTB_DOCKER=1
ENV DISPLAY=:99

RUN mkdir -p /etc/supervisor/conf.d

RUN printf "[supervisord]\n\
nodaemon=true\n\
user=root\n\
\n\
[program:xvfb]\n\
command=/usr/bin/Xvfb :99 -screen 0 1280x720x16\n\
autorestart=true\n\
priority=100\n\
\n\
[program:fluxbox]\n\
command=/usr/bin/fluxbox\n\
environment=DISPLAY=\":99\"\n\
autorestart=true\n\
priority=200\n\
\n\
[program:x11vnc]\n\
command=/usr/bin/x11vnc -display :99 -nopw -shared -forever -loop -noxdamage -repeat -nobell -wait 50\n\
autorestart=true\n\
priority=300\n\
startsecs=5\n\
\n\
[program:app]\n\
command=python main.py\n\
directory=/app\n\
environment=DISPLAY=\":99\"\n\
autorestart=unexpected\n\
stopasgroup=true\n\
killasgroup=true\n\
startsecs=5\n\
startretries=3\n\
stdout_logfile=/dev/fd/1\n\
stdout_logfile_maxbytes=0\n\
stderr_logfile=/dev/fd/2\n\
stderr_logfile_maxbytes=0\n\
priority=400\n" > /etc/supervisor/conf.d/supervisord.conf

EXPOSE 5900 7860
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]