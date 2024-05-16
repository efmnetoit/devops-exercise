#!/bin/bash
clear

# Verifica se a imagem devops-exercise existe no docker:
echo
echo "Verificando se a imagem devops-exercise já existe"
echo 
if [[ "$(docker images -q devops-exercise)" == "" ]]; then
    # Se a imagem não existir, será criada a seguir:
    docker build -t devops-exercise .
fi

# Chamando aplicação
echo 
echo "Chamando a aplicação via docker compose"
echo
docker compose --env-file ./env/.env_sample up -d

# Limpa a tela
clear

# Lista os containers criados
echo 
echo "#######################################################################################################"
echo "                                                                                                       "
echo "    >>> Para executar sua aplicação digite no browser: http://localhost                                "
echo "                                                                                                       "
echo "    Obs.: O tráfego será automaticamente redirecionado para https, porém na 1ª vez será necessário     "
echo "    autorizar no browser pois o certificado não é de uma entidade certificadora reconhecida, criado    "
echo "    para localhost somente, apenas para teste da aplicação.                                            "
echo "                                                                                                       "
echo "   Segue lista dos containers criados, para finalizar a aplicação use o comando: docker compose down   "
echo "                                                                                                       "
echo "#######################################################################################################"
echo
docker ps
echo