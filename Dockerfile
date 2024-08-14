FROM xieyunshen2020/paddleqa:code-clone-git2.34
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]