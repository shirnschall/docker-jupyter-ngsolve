FROM python:3.12

# System dependencies NGSolve and friends typically need at runtime
# (OpenGL/X11 libs for mesh rendering fallback, build tools in case any
# package needs to compile something, curl for healthchecks)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libglu1-mesa \
    libxrender1 \
    libxext6 \
    libsm6 \
    curl \
    libgfortran5 \
    libquadmath0 \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Install Python packages
RUN pip install --no-cache-dir \
    jupyterlab \
    jupyter-resource-usage \
    jupytext \
    ngsolve \
    anywidget \
    webgpu \
    ngsolve_webgpu \
    sympy \
    pandas \
    matplotlib \
    plotly \
    numpy \
    scipy \
    tqdm \
    pathlib \
    pytest

# Notebook working directory — mount your TrueNAS SSD dataset here
# A second mount point, /vault-user, is intended for your HDD array
# (mass storage) — mounted at container runtime, not built into the image.
# Permissions on these paths come entirely from whatever host
# dataset/directory you mount over them — nothing to set here.
WORKDIR /workspace
RUN mkdir -p /vault-user

# Jupyter needs a writable $HOME to store its own runtime/config files
# (separate from your notebooks). Since we don't create a named user in
# this image and TrueNAS/local runs may pass an arbitrary UID with no
# /etc/passwd entry, that UID has no defined home directory and Jupyter
# fails trying to write under /. Give it a dedicated, world-writable
# home instead so it works no matter which UID ends up running it.
ENV HOME=/home/jupyter
RUN mkdir -p ${HOME} && chmod 777 ${HOME}

# No user is created or set here. TrueNAS's Custom App "run as user"
# setting overrides the runtime UID/GID directly (equivalent to
# `docker run --user <uid>:<gid>`) — same mechanism you already use
# for your other TrueNAS apps.
#
# For local Mac testing, pass --user explicitly, e.g.:
#   docker run --user $(id -u):$(id -g) ...

EXPOSE 8888

# No token/password baked in here — set JUPYTER_TOKEN as an environment
# variable in the TrueNAS app config instead. If unset, Jupyter will
# generate a random token each start (visible in container logs).
# Shell form (not exec form) so ${JUPYTER_TOKEN} actually gets expanded.
CMD jupyter lab \
    --ip=0.0.0.0 \
    --port=8888 \
    --no-browser \
    --notebook-dir=/workspace \
    --ServerApp.token="${JUPYTER_TOKEN}" \
    --ResourceUseDisplay.track_cpu_percent=True \
    --ResourceUseDisplay.enable_prometheus_metrics=False