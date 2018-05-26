FROM java:8

# explicitly set user/group IDs
RUN groupadd -r cassandra --gid=999 && useradd -r -g cassandra --uid=999 cassandra

ENV GOSU_VERSION 1.10

# Add DataStax sources
RUN curl -L http://debian.datastax.com/debian/repo_key | apt-key add -
RUN echo "deb http://debian.datastax.com/community stable main" > /etc/apt/sources.list.d/datastax.list

# Workaround for https://github.com/docker/docker/issues/6345
RUN ln -s -f /bin/true /usr/bin/chfn

ENV CASSANDRA_VERSION 3.11.2

# Install Cassandra 3.11.2
ENV GPG_KEYS \
# gpg: key 0353B12C: public key "T Jake Luciani <jake@apache.org>" imported
	514A2AD631A57A16DD0047EC749D6EEC0353B12C \
# gpg: key FE4B2BDA: public key "Michael Shuler <michael@pbandjelly.org>" imported
	A26E528B271F19B9E5D8E19EA278B781FE4B2BDA
RUN set -ex; \
	export GNUPGHOME="$(mktemp -d)"; \
	for key in $GPG_KEYS; do \
		gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
	done; \
	gpg --export $GPG_KEYS > /etc/apt/trusted.gpg.d/cassandra.gpg; \
	rm -rf "$GNUPGHOME"; \
	apt-key list

ENV CASSANDRA_VERSION 3.11.2

RUN set -ex; \
	\
# https://bugs.debian.org/877677
# update-alternatives: error: error creating symbolic link '/usr/share/man/man1/rmid.1.gz.dpkg-tmp': No such file or directory
	mkdir -p /usr/share/man/man1/; \
	\
	dpkgArch="$(dpkg --print-architecture)"; \
	case "$dpkgArch" in \
		amd64|i386) \
# arches officialy included in upstream's repo metadata
			echo 'deb http://www.apache.org/dist/cassandra/debian 311x main' > /etc/apt/sources.list.d/cassandra.list; \
			apt-get update; \
			;; \
		*) \
# we're on an architecture upstream doesn't include in their repo Architectures
# but their provided packages are "Architecture: all" so we can download them directly instead
			\
# save a list of installed packages so build deps can be removed cleanly
			savedAptMark="$(apt-mark showmanual)"; \
			\
# fetch a few build dependencies
			apt-get update; \
			apt-get install -y --no-install-recommends \
				wget ca-certificates \
				dpkg-dev \
			; \
# we don't remove APT lists here because they get re-downloaded and removed later
			\
# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
# (which is done after we install the built packages so we don't have to redownload any overlapping dependencies)
			apt-mark showmanual | xargs apt-mark auto > /dev/null; \
			apt-mark manual $savedAptMark; \
			\
# download the two "arch: all" packages we need
			tempDir="$(mktemp -d)"; \
			for pkg in cassandra cassandra-tools; do \
				deb="${pkg}_${CASSANDRA_VERSION}_all.deb"; \
				wget -O "$tempDir/$deb" "https://www.apache.org/dist/cassandra/debian/pool/main/c/cassandra/$deb"; \
			done; \
			\
# create a temporary local APT repo to install from (so that dependency resolution can be handled by APT, as it should be)
			ls -lAFh "$tempDir"; \
			( cd "$tempDir" && dpkg-scanpackages . > Packages ); \
			grep '^Package: ' "$tempDir/Packages"; \
			echo "deb [ trusted=yes ] file://$tempDir ./" > /etc/apt/sources.list.d/temp.list; \
# work around the following APT issue by using "Acquire::GzipIndexes=false" (overriding "/etc/apt/apt.conf.d/docker-gzip-indexes")
#   Could not open file /var/lib/apt/lists/partial/_tmp_tmp.ODWljpQfkE_._Packages - open (13: Permission denied)
#   ...
#   E: Failed to fetch store:/var/lib/apt/lists/partial/_tmp_tmp.ODWljpQfkE_._Packages  Could not open file /var/lib/apt/lists/partial/_tmp_tmp.ODWljpQfkE_._Packages - open (13: Permission denied)
			apt-get -o Acquire::GzipIndexes=false update; \
			;; \
	esac; \
	\
	apt-get install -y \
		cassandra="$CASSANDRA_VERSION" \
		cassandra-tools="$CASSANDRA_VERSION" \
	; \
	\
	rm -rf /var/lib/apt/lists/*; \
	\
	if [ -n "$tempDir" ]; then \
# if we have leftovers from building, let's purge them (including extra, unnecessary build deps)
		apt-get purge -y --auto-remove; \
		rm -rf "$tempDir" /etc/apt/sources.list.d/temp.list; \
	fi
# RUN echo "deb http://debian.datastax.com/community stable main" \ 
#     | sudo tee -a /etc/apt/sources.list.d/cassandra.sources.list \
#     curl -L http://debian.datastax.com/debian/repo_key | sudo apt-key add -

# RUN apt-get update && \
#     apt-get install -y \
# 		cassandra="$CASSANDRA_VERSION" \
# 		cassandra-tools="$CASSANDRA_VERSION" && \
#     rm -rf /var/lib/apt/lists/*

ENV CASSANDRA_CONFIG /etc/cassandra

# Run base config script
ADD scripts/config-cassandra.sh /usr/local/bin/config-cassandra
RUN /usr/local/bin/config-cassandra

RUN rm -f /etc/security/limits.d/cassandra.conf

EXPOSE 7199 7000 7001 9160 9042 22 8012 61621

CMD [""]