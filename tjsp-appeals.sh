#!/bin/bash

#SBATCH -p general
#SBATCH -N 1
#SBATCH --mem=10g
#SBATCH -n 64
#SBATCH -t 2-
#SBATCH --mail-user=andre.assumpcao@gmail.com
#SBATCH --mail-type=ALL

R CMD BATCH --no-save 02_download_appealscases.R