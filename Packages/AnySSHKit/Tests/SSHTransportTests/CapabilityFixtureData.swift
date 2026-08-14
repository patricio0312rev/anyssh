import Foundation

enum CapabilityFixtureData {
    static let everythingPresent = Data(
        #"""
        anyssh-capabilities/1
        shell	/bin/zsh
        platform	Darwin arm64
        locale	en_US.UTF-8
        home	/Users/dev
        path	/Users/dev/.local/bin:/opt/homebrew/bin:/usr/bin
        git.path	/opt/homebrew/bin/git
        git.version	git version 2.54.0
        tmux.path	/opt/homebrew/bin/tmux
        tmux.version	tmux 3.6a
        herdr.path	/Users/dev/.local/bin/herdr
        herdr.version	herdr 0.8.0
        herdr.protocol	19
        """#.utf8)

    static let gitOnly = Data(
        #"""
        anyssh-capabilities/1
        shell	/bin/bash
        platform	Linux x86_64
        locale	C.UTF-8
        home	/home/dev
        path	/usr/local/bin:/usr/bin:/bin
        git.path	/usr/bin/git
        git.version	git version 2.43.0
        tmux.path	
        tmux.version	
        herdr.path	
        herdr.version	
        herdr.protocol	
        """#.utf8)

    static let nothingPresent = Data(
        #"""
        anyssh-capabilities/1
        shell	/bin/sh
        platform	FreeBSD amd64
        locale	C
        home	/home/operator
        path	/usr/bin:/bin
        git.path	
        git.version	
        tmux.path	
        tmux.version	
        herdr.path	
        herdr.version	
        herdr.protocol	
        """#.utf8)

    static let oldGit = Data(
        #"""
        anyssh-capabilities/1
        shell	/bin/zsh
        platform	Darwin arm64
        locale	en_US.UTF-8
        home	/Users/legacy
        path	/usr/bin:/bin:/usr/sbin:/sbin
        git.path	/usr/bin/git
        git.version	git version 2.30.1
        tmux.path	
        tmux.version	
        herdr.path	
        herdr.version	
        herdr.protocol	
        """#.utf8)
}
