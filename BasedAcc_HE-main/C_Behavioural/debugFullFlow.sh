echo "Compiling HEmul.c"
gcc -o debugHEmul debugHEmul.c -lm -lgmp
echo "Running HEmul"
./debugHEmul
echo "Decrypting"
python3 crypt.py large