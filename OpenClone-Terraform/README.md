Versions used when it worked:

VSCode: 1.93.1

WSL version: 2.2.4.0

Docker version: 27.2.0

Dev Containers: v0.384.0

Terraform 1.9.6

------------------------------------------------

**HOW DEPLOYING CONTAINER CHANGES WORK**

The containers that get deployed to vultr originate from your local docker. So first step is to `build them using docker build --no-cache -t openclone-whatever:1.0 .`. The IAC is currently hard coded to look for the 1.0 tag. However, when push-containers.sh runs it iteratively queries vultr for all images for the particular container name starting with 1.0, then 2.0, etc. until it doesn't find one. So if it goes until openclone-whatever:13.0 before it can't find one that means the latest version† tag for openclone-whatever on vultr is 12.0. This is the only way I could figure out how to do it as nothing I tried was able to get a list of images tags for a particular container/repository from vultr. Anyways once it knows the current version (12.0 if we are sticking with my fictional example) it adds 1 to it, so the image name of the new remote image will be openclone-whatever:13.0 (*the local image will still be openclone-whatever:1.0*). Having an updated tag seems to be mandatory because when I would make code changes and reuse the same tags (openclone-whatever:12.0 to continue with the fictional example) vultr would not run my new container image. The only way to get it to update the container image was to change the tag. The best way I could figure to update the tag was to use a counter (1.0, 2.0, etc.) however, getting the current tag, as I mentioned, was not straight forward. I had to hack something together in order to do it. The process that seems to work is:

1. delete local docker image
2. rebuild local docker image (using 1.0 tag - e.g. openclone-whatever:1.0)
3. run push-containers.sh
4. run create.sh --create

† the version on vultr (1.0, 2.0, etc.) is more of a uniquifier than a true version and can be reset to 1.0 if, for example the container registry is destroyed and recreated. the local version, while hard coded to always be 1.0 in the IAC, is better thought of as the true version as theoretically there could be a 2.0 used locally in the future if there were a code change big enough to deserve the 2.0 moniker.

------------------------------------------------

IF YOU DELETE AND RECREATE THE CONTAINER YOU HAVE TO RUN .DESTROY.SH OTHERWISE THE OLD .TFSTATE FILES WILL STILL BE IN THERE



-------------------------------------------------