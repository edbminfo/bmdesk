import os
import shutil
import subprocess
import sys

def run_command(command, ignore_errors=False):
    """Executa um comando no shell e imprime a saída."""
    print(f"> {command}")
    try:
        if os.name == 'nt': # Windows
            subprocess.run(command, shell=True, check=True)
        else:
            subprocess.run(command, shell=True, check=True, executable='/bin/bash')
    except subprocess.CalledProcessError as e:
        if not ignore_errors:
            print(f"Erro ao executar: {command}")
            print(f"Detalhes: {e}")
            sys.exit(1)
        else:
            print(f"Aviso (ignorado): {e}")

def corrigir_submodulo():
    caminho_submodulo = os.path.join('libs', 'hbb_common')
    caminho_git_interno = os.path.join('.git', 'modules', 'libs', 'hbb_common')
    url_nova = "https://github.com/edbminfo/hbb_common"

    print("--- INICIANDO CORREÇÃO DO SUBMÓDULO ---\n")

    # 1. Desregistrar o submódulo antigo (limpa config)
    print("1. Desregistrando submódulo antigo...")
    run_command(f'git submodule deinit -f "{caminho_submodulo}"', ignore_errors=True)

    # 2. Remover do índice do git (remove a referência ao hash quebrado)
    # --cached remove apenas do índice, mas como vamos apagar a pasta depois, tudo bem.
    print("2. Removendo referência antiga do índice do Git...")
    run_command(f'git rm --cached "{caminho_submodulo}"', ignore_errors=True)

    # 3. Limpeza física das pastas
    print("3. Limpando diretórios remanescentes...")
    if os.path.exists(caminho_submodulo):
        shutil.rmtree(caminho_submodulo, ignore_errors=True)
        # Garantia extra para Windows
        if os.path.exists(caminho_submodulo):
             run_command(f'rmdir /s /q "{caminho_submodulo}"', ignore_errors=True)
    
    # Limpar a pasta interna do .git (onde o histórico do submódulo fica guardado)
    # Isso é crucial para evitar conflitos de URL
    if os.path.exists(caminho_git_interno):
        print(f"   Removendo cache interno: {caminho_git_interno}")
        shutil.rmtree(caminho_git_interno, ignore_errors=True)
        if os.path.exists(caminho_git_interno):
             run_command(f'rmdir /s /q "{caminho_git_interno}"', ignore_errors=True)

    # 4. Adicionar o submódulo novamente (Isso cria a referência correta para o NOVO hash)
    print(f"4. Adicionando o novo repositório: {url_nova}")
    # --force é usado caso o git ache que o diretório ainda é ignorado
    run_command(f'git submodule add --force "{url_nova}" "{caminho_submodulo}"')

    print("\n--- SUCESSO! ---")
    print("O submódulo foi recriado apontando para o commit mais recente do novo repositório.")
    print("Não esqueça de fazer o commit dessa mudança no repositório pai:")
    print('   git add .gitmodules libs/hbb_common')
    print('   git commit -m "Alterado submódulo hbb_common para edbminfo"')

if __name__ == "__main__":
    corrigir_submodulo()