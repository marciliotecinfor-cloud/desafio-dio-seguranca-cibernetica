# Auditoria de Segurança: Simulação de Ataques Brute Force com Kali Linux e Medusa

> Projeto educacional da formação em Segurança Cibernética — DIO  
> Autor: **Marcílio Silva de Santana**  
> Ambiente: laboratório local e isolado, com autorização.

## 1. Visão geral

Este projeto demonstra como avaliar a resistência de serviços de rede e aplicações web a tentativas automatizadas de autenticação. O laboratório utiliza Kali Linux, Medusa, Metasploitable 2 e DVWA (Damn Vulnerable Web Application).

O objetivo não é comprometer sistemas reais. Todos os testes devem ocorrer exclusivamente em máquinas virtuais próprias, em uma rede isolada, com credenciais de laboratório.

## 2. Objetivos

- Compreender ataques de força bruta e password spraying.
- Conhecer o uso da ferramenta Medusa em auditorias autorizadas.
- Identificar riscos de senhas fracas e ausência de controles de autenticação.
- Registrar evidências e resultados de forma reproduzível.
- Recomendar medidas de prevenção e monitoramento.

## 3. Escopo e regras de segurança

**Alvos permitidos:** somente as VMs configuradas pelo estudante.  
**Rede:** Host-Only ou rede interna do VirtualBox, sem exposição à internet.  
**Proibido:** testar IPs públicos, redes corporativas, contas de terceiros ou qualquer sistema sem autorização explícita.

Use snapshots antes dos testes. Mantenha baixa concorrência e wordlists pequenas. Interrompa o teste se houver instabilidade.

## 4. Arquitetura do laboratório

| Máquina | Função | Rede |
|---|---|---|
| Kali Linux | Estação de auditoria | Host-Only |
| Metasploitable 2 | Alvo vulnerável para FTP/SMB e, se disponível, DVWA | Host-Only |

Exemplo de endereçamento (ajuste ao seu VirtualBox):
- Kali: `192.168.56.101`
- Metasploitable 2: `192.168.56.102`

Os endereços acima são apenas exemplos. Confirme os endereços reais com `ip a` no Kali e `ifconfig` no Metasploitable.

### 4.1 Configuração no VirtualBox

1. Desligue as duas VMs.
2. Em **Configurações > Rede > Adaptador 1**, habilite o adaptador e selecione **Host-only Adapter** (ou uma rede interna compartilhada pelas VMs).
3. Selecione o mesmo nome de rede nas duas VMs.
4. Não configure encaminhamento de portas nem interface em bridge.
5. Inicie as VMs e confirme a conectividade.

No Kali:

```bash
ip a
ip route
ping -c 3 192.168.56.102
```

No Metasploitable 2:

```bash
ifconfig
```

Se não houver conectividade, revise se as duas VMs estão na mesma rede e sub-rede.

## 5. Preparação do Kali Linux

Atualize os índices e instale as ferramentas:

```bash
sudo apt update
sudo apt install -y medusa nmap smbclient enum4linux-ng
medusa -V
medusa -d
```

O comando `medusa -d` lista os módulos disponíveis na instalação. Confirme os módulos `ftp`, `smbnt` e `http` antes de utilizá-los.

## 6. Reconhecimento controlado

Defina o IP do alvo conforme o endereço observado no laboratório:

```bash
TARGET=192.168.56.102
nmap -sV -p 21,80,139,445 "$TARGET"
```

Registre somente os serviços encontrados. A presença de uma porta aberta não significa, por si só, que o serviço esteja vulnerável.

## 7. Cenário 1 — Auditoria de autenticação FTP

### Objetivo
Verificar, com uma lista pequena de credenciais fictícias, se o serviço FTP aceita senhas fracas.

### Arquivos
As wordlists deste repositório são exemplos didáticos e não contêm credenciais de pessoas reais.

### Comando de auditoria

Execute somente contra a VM de laboratório, depois de confirmar que a porta 21 está aberta:

```bash
medusa -h 192.168.56.102 -U wordlists/usuarios.txt \
  -P wordlists/senhas-lab.txt -M ftp -t 2 -f -v 4 \
  -O resultados-ftp.txt
```

**Parâmetros principais:**
- `-h`: endereço do alvo autorizado.
- `-U`: arquivo com usuários de teste.
- `-P`: arquivo com senhas de teste.
- `-M ftp`: módulo FTP.
- `-t 2`: limita a duas tentativas concorrentes.
- `-f`: interrompe a auditoria do host após encontrar uma credencial válida.
- `-O`: grava o log em arquivo.

### Validação
Se o Medusa reportar uma combinação válida, confirme-a manualmente no serviço FTP do laboratório, sem reutilizar a credencial em nenhum outro sistema. Registre o resultado real, a data e a evidência. Se nenhuma combinação funcionar, registre isso — não invente um acesso bem-sucedido.

## 8. Cenário 2 — Formulário web no DVWA

O DVWA possui um módulo didático chamado **Brute Force**. Em versões comuns, o endereço é:

`http://192.168.56.102/dvwa/`

Confirme o caminho correto no seu ambiente. Se o DVWA não estiver instalado no Metasploitable 2, instale-o em uma VM própria e isolada seguindo a documentação oficial.

### Procedimento

1. Acesse o DVWA pelo navegador do Kali.
2. Faça a configuração inicial pelo menu **Setup / Reset DB**, se necessário.
3. Entre no módulo **Brute Force**.
4. Configure o nível de segurança **Low** apenas para a demonstração.
5. Faça uma tentativa manual com credenciais fictícias e observe a resposta.
6. Use o navegador/DevTools ou Burp Suite Community para inspecionar a requisição HTTP gerada pelo formulário.
7. Registre método, caminho, nomes dos parâmetros, cookies de sessão e texto de resposta de falha.
8. Faça a automação apenas nesse endpoint local, com uma lista curta e limite de tentativas.

### Sobre o uso do Medusa

O módulo HTTP do Medusa depende do formato exato do formulário e da resposta da aplicação. Não existe um comando universal que funcione em todas as versões do DVWA: cookies, token CSRF, parâmetros e mensagens podem mudar. Consulte a ajuda do módulo instalado:

```bash
medusa -q -M http
```

Use as informações capturadas no seu próprio DVWA para adaptar os parâmetros do módulo. Não copie um comando genérico sem validar o formato. Se a versão do formulário exigir token CSRF dinâmico ou tratamento de sessão que o módulo não suporte, documente a limitação e use Burp Suite Intruder ou OWASP ZAP em modo manual/controlado, com o alvo local.

### Validação e evidências

Registre:
- URL local utilizada;
- nível de segurança do DVWA;
- quantidade de tentativas realizadas;
- resposta de falha e comportamento após várias tentativas;
- se houve bloqueio, atraso, CAPTCHA ou limitação;
- captura de tela sem expor cookies ou dados sensíveis.

## 9. Cenário 3 — Enumeração e password spraying em SMB

### Objetivo
Entender a exposição de informações de usuários e avaliar, em laboratório, o risco de uma senha fraca compartilhada por várias contas.

Primeiro, identifique as portas SMB:

```bash
nmap -sV -p 139,445 192.168.56.102
```

Enumeração básica no alvo de laboratório:

```bash
enum4linux-ng -U 192.168.56.102
```

Também é possível consultar compartilhamentos:

```bash
smbclient -L //192.168.56.102 -N
```

A enumeração pode falhar quando o serviço restringe consultas anônimas; isso também é um resultado válido a documentar.

### Password spraying de baixa intensidade

Password spraying testa **uma senha de laboratório por vez** em uma pequena lista de usuários. Para evitar bloqueios e impacto desnecessário, use somente contas fictícias criadas para o exercício, uma única senha fraca de teste e concorrência mínima.

```bash
medusa -h 192.168.56.102 -U wordlists/usuarios.txt \
  -p 'SenhaFraca-Lab-2026' -M smbnt -t 1 -f -v 4 \
  -O resultados-smb.txt
```

Confirme antes que `smbnt` aparece na lista de módulos (`medusa -d`). Não use listas extensas nem repita ciclos contra o serviço.

### Interpretação

- Uma conta aceita a senha de teste: evidência de política de senha inadequada no laboratório.
- Nenhuma conta aceita a senha: não prova que todas as contas estejam seguras; apenas que a senha testada não foi aceita.
- Enumeração anônima bloqueada: controle positivo que reduz exposição de informações.

## 10. Resultados e registro

**Importante:** este repositório é um modelo de documentação. Nenhum resultado de execução é declarado como real até que o estudante rode os testes e preencha a tabela abaixo.

| Teste | Alvo/serviço | Resultado observado | Evidência |
|---|---|---|---|
| FTP | `192.168.56.102:21` | A preencher após execução | `images/ftp.png` |
| DVWA | endpoint local do módulo Brute Force | A preencher após execução | `images/dvwa.png` |
| SMB | `192.168.56.102:139/445` | A preencher após execução | `images/smb.png` |

### Modelo de anotação

- Data e horário:
- Versões das VMs e ferramentas:
- IP do alvo (somente laboratório):
- Serviço e porta:
- Quantidade de usuários/senhas testados:
- Resultado observado:
- Evidência:
- Limitações encontradas:
- Medida corretiva recomendada:

Não publique senhas reais, cookies, tokens, endereços públicos ou informações de terceiros nas capturas de tela.

## 11. Recomendações de mitigação

1. **Senhas fortes:** exigir comprimento adequado e bloquear senhas comuns ou já comprometidas.
2. **MFA:** habilitar autenticação multifator sempre que possível.
3. **Limitação de tentativas:** aplicar rate limiting, atrasos progressivos e bloqueios temporários proporcionais.
4. **Monitoramento:** alertar para falhas repetidas, tentativas distribuídas e password spraying.
5. **Mensagens genéricas:** evitar revelar se o usuário existe durante a autenticação.
6. **SMB:** desabilitar SMBv1, restringir portas 139/445 por firewall, exigir autenticação e limitar enumeração/compartilhamentos.
7. **FTP:** substituir FTP sem criptografia por SFTP ou FTPS e desabilitar contas anônimas quando não forem necessárias.
8. **Web:** proteger formulários com CSRF tokens, sessões seguras, rate limiting, MFA e controles contra automação.
9. **Privilégio mínimo:** conceder a cada conta somente as permissões necessárias.
10. **Auditorias periódicas:** revisar políticas, logs e contas inativas.

## 12. Conclusão

A atividade demonstra que a segurança da autenticação depende de mais do que uma senha: controles de tentativa, monitoramento, configuração dos serviços, proteção de sessão e autenticação multifator são componentes essenciais.

O uso do Kali Linux e do Medusa em um ambiente isolado permite compreender como tentativas automatizadas podem identificar credenciais fracas e como os serviços respondem a esse comportamento. A documentação dos resultados também reforça a importância de evidências verificáveis e de uma postura ética durante auditorias.

## 13. Referências

- Kali Linux. **Medusa**. https://www.kali.org/tools/medusa/
- Digininja. **Damn Vulnerable Web Application (DVWA)**. https://github.com/digininja/DVWA
- Oracle. **VirtualBox User Manual**. https://www.virtualbox.org/manual/
- Nmap Project. **Nmap Reference Guide**. https://nmap.org/book/man.html
- Samba. **smbclient manual**. https://www.samba.org/samba/docs/current/man-html/smbclient.1.html
- GitHub Docs. **Getting started with your GitHub account**. https://docs.github.com/en/get-started

---

## 14. Publicação no GitHub

Crie um repositório público com o nome `auditoria-bruteforce-kali-medusa` e envie os arquivos desta pasta.

Pelo terminal, dentro da pasta do projeto:

```bash
git init
git add .
git commit -m "Adiciona projeto de auditoria com Kali Linux e Medusa"
git branch -M main
git remote add origin https://github.com/SEU-USUARIO/auditoria-bruteforce-kali-medusa.git
git push -u origin main
```

Substitua `SEU-USUARIO` pelo seu usuário do GitHub. Antes de entregar na DIO, preencha a seção de resultados e adicione capturas de tela reais em `images/`.
