# BasedOn https://github.com/acmert/bfv-python

import sys
import numpy as np

import random
from random import randint
from random import randint,gauss

import math
from math import log,ceil


# Critical Functions
# Modular inverse of an integer
def egcd(a, b):
    if a == 0:
        return (b, 0, 1)
    else:
        g, y, x = egcd(b % a, a)
        return (g, x - (b // a) * y, y)

def modinv(a, m):
    g, x, y = egcd(a, m)
    if g != 1:
        raise Exception('Modular inverse does not exist')
    else:
        return x % m

# Bit-Reverse integer
def intReverse(a,n):
    b = ('{:0'+str(n)+'b}').format(a)
    return int(b[::-1],2)

# Bit-Reversed index
def indexReverse(a,r):
    n = len(a)
    b = [0]*n
    for i in range(n):
        rev_idx = intReverse(i,r)
        b[rev_idx] = a[i]
    return b
    
def NTT(A, W_table, q):
    # print("DEBUG q:{}".format(q))
    n = len(A)
    B = [x for x in A]

    v = int(math.log(n, 2))

    for i in range(0, v):
        for j in range(0, (2 ** i)):
            for k in range(0, (2 ** (v - i - 1))):
                s = j * (2 ** (v - i)) + k
                t = s + (2 ** (v - i - 1))

                # w = (W ** ((2 ** i) * k)) % q
                w = W_table[((2 ** i) * k)]

                as_temp = B[s]
                at_temp = B[t]

                B[s] = (as_temp + at_temp) % q
                B[t] = ((as_temp - at_temp) * w) % q

    B = indexReverse(B, v)

    return B

def INTT(A, W_table, q):
    n = len(A)
    B = [x for x in A]

    v = int(math.log(n, 2))
    
    for i in range(0, v):
        for j in range(0, (2 ** i)):
            for k in range(0, (2 ** (v - i - 1))):
                s = j * (2 ** (v - i)) + k
                t = s + (2 ** (v - i - 1))

                # w = (W ** ((2 ** i) * k)) % q
                w = W_table[((2 ** i) * k)]

                as_temp = B[s]
                at_temp = B[t]

                B[s] = (as_temp + at_temp) % q
                B[t] = ((as_temp - at_temp) * w) % q

    B = indexReverse(B, v)

    n_inv = modinv(n, q)
    for i in range(n):
        B[i] = (B[i] * n_inv) % q

    return B

# Critical Classes
class Poly:
    def __init__(self, n, q, np=[0,0,0,0]):
        self.n = n
        self.q = q
        self.np= np # NTT parameters: [w,w_inv,psi,psi_inv]
        self.F = [0]*n
        self.inNTT = False
    #
    def randomize(self, B, domain=False, type=0, mu=0, sigma=0):
        # type:0 --> uniform
        # type:1 --> gauss
        if type == 0:
            self.F = [randint(-(B//2), B//2)%self.q for i in range(self.n)]
            self.inNTT = domain
        else:
            self.F = [int(gauss(mu,sigma))%self.q for i in range(self.n)]
            self.inNTT = domain
    #
    def __add__(self, b):
        if self.inNTT != b.inNTT:
            raise Exception("Polynomial Addiditon: Inputs must be in the same domain.")
        elif self.q != b.q:
            raise Exception("Polynomial Addiditon: Inputs must have the same modulus")
        else:
            c = Poly(self.n, self.q, self.np)
            c.F = [(x+y)%self.q for x,y in zip(self.F,b.F)]
            c.inNTT = self.inNTT
            return c
    #
    def __sub__(self, b):
        if self.inNTT != b.inNTT:
            raise Exception("Polynomial Subtraction: Inputs must be in the same domain.")
        elif self.q != b.q:
            raise Exception("Polynomial Subtraction: Inputs must have the same modulus")
        else:
            c = Poly(self.n, self.q, self.np)
            c.F = [(x-y)%self.q for x,y in zip(self.F,b.F)]
            c.inNTT = self.inNTT
            return c
    #
    def __mul__(self, b):        
        if self.inNTT != b.inNTT:
            raise Exception("Polynomial Multiplication: Inputs must be in the same domain.")
        elif self.q != b.q:
            raise Exception("Polynomial Multiplication: Inputs must have the same modulus")
        else:
            """
            Assuming both inputs in POL/NTT domain
            If in NTT domain --> Coeff-wise multiplication
            If in POL domain --> Full polynomial multiplication
            """
            c = Poly(self.n, self.q, self.np)
            if self.inNTT == True and b.inNTT == True:
                c.F = [((x*y)%self.q) for x,y in zip(self.F,b.F)]
                c.inNTT = True
            else:
                # x1=self*psi, x2=b*psi
                # x1n = NTT(x1,w), x2n = NTT(x2,w)
                # x3n = x1n*x2n
                # x3 = INTT(x3n,w_inv)
                # c = x3*psi_inv

                w_table    = self.np[0]
                wv_table   = self.np[1]
                psi_table  = self.np[2]
                psiv_table = self.np[3]

                s_p = [(x*psi_table[pwr])%self.q for pwr,x in enumerate(self.F)]
                b_p = [(x*psi_table[pwr])%self.q for pwr,x in enumerate(b.F)]
                s_n = NTT(s_p,w_table,self.q)
                b_n = NTT(b_p,w_table,self.q)
                sb_n= [(x*y)%self.q for x,y in zip(s_n,b_n)]
                sb_p= INTT(sb_n,wv_table,self.q)
                sb  = [(x*psiv_table[pwr])%self.q for pwr,x in enumerate(sb_p)]

                c.F = sb
                c.inNTT = False
            return c
    #
    def __mod__(self,base):
        b = Poly(self.n, self.q, self.np)
        b.F = [(x%base) for x in self.F]
        b.inNTT = self.inNTT
        return b
    #
    def __round__(self):
        b = Poly(self.n, self.q, self.np)
        b.F = [round(x) for x in self.F]
        b.inNTT = self.inNTT
        return b
    #
    def __neg__(self):
        b = Poly(self.n, self.q, self.np)
        b.F = [((-x) % self.q) for x in self.F]
        b.inNTT = self.inNTT
        return b
    
class BFV:
    # Definitions
    # Z_q[x]/f(x) = x^n + 1 where n=power-of-two

    # Operations
    # -- SecretKeyGen
    # -- PublicKeyGen
    # -- Encryption
    # -- Decryption
    # -- EvaluationKeyGenV1
    # -- EvaluationKeyGenV2 (need to be fixed)
    # -- HomAdd
    # -- HomMult
    # -- RelinV1
    # -- RelinV2 (need to be fixed)

    # Parameters
    # (From outside)
    # -- n (ring size)
    # -- q (ciphertext modulus)
    # -- t (plaintext modulus)
    # -- mu (distribution mean)
    # -- sigma (distribution std. dev.)
    # -- qnp (NTT parameters: [w,w_inv,psi,psi_inv])
    # (Generated with parameters)
    # -- sk
    # -- pk
    # -- rlk1, rlk2

    def __init__(self, n, q, t, mu, sigma, qnp):
        self.n = n
        self.q = q
        self.t = t
        self.T = 0
        self.l = 0
        self.p = 0
        self.mu = mu
        self.sigma = sigma
        self.qnp= qnp # array NTT parameters: [w,w_inv,psi,psi_inv]
        #
        self.sk = []
        self.pk = []
        self.rlk1 = []
        self.rlk2 = []
        self.rlk_store = []
    #
    def __str__(self):
        str = "\n--- Parameters:\n"
        str = str + "n    : {}\n".format(self.n)
        str = str + "q    : {}\n".format(self.q)
        str = str + "t    : {}\n".format(self.t)
        str = str + "T    : {}\n".format(self.T)
        str = str + "l    : {}\n".format(self.l)
        str = str + "p    : {}\n".format(self.p)
        str = str + "mu   : {}\n".format(self.mu)
        str = str + "sigma: {}\n".format(self.sigma)
        return str
    #
    def SecretKeyGen(self):
        """
        sk <- R_2
        """
        s = Poly(self.n,self.q,self.qnp)
        s.randomize(2)
        self.sk = s
    #
    def PublicKeyGen(self):
        """
        a <- R_q
        e <- X
        pk[0] <- (-(a*sk)+e) mod q
        pk[1] <- a
        """
        a, e = Poly(self.n,self.q,self.qnp), Poly(self.n,self.q,self.qnp)
        a.randomize(self.q)
        e.randomize(0, domain=False, type=1, mu=self.mu, sigma=self.sigma)
        pk0 = -(a*self.sk + e)
        pk1 = a
        self.pk = [pk0,pk1]
    #
    def EvalKeyGenV1(self, T):
        self.T = T
        self.l = int(math.floor(math.log(self.q,self.T)))
        
        rlk1 = []
        
        sk2 = (self.sk * self.sk)

        for i in range(self.l+1):
            ai   , ei    = Poly(self.n,self.q,self.qnp), Poly(self.n,self.q,self.qnp)
            ai.randomize(self.q)
            ei.randomize(0, domain=False, type=1, mu=self.mu, sigma=self.sigma)

            Ts2   = Poly(self.n,self.q,self.qnp)
            Ts2.F = [((self.T**i)*j) % self.q for j in sk2.F]

            rlki0 = Ts2 - (ai*self.sk + ei)
            rlki1 = ai

            rlk1.append([rlki0,rlki1])
            
            # formatting
            rlk1.append([rlki0,rlki1])
            self.rlk_store.append([rlki0.F, rlki1.F])
        
        self.rlk1 = rlk1
    #
    def Encryption(self, m):
        """
        delta = floor(q/t)

        u  <- random polynomial from R_2
        e1 <- random polynomial from R_B
        e2 <- random polynomial from R_B

        c0 <- pk0*u + e1 + m*delta
        c1 <- pk1*u + e2
        """
        delta = int(math.floor(self.q/self.t))

        u, e1, e2 = Poly(self.n,self.q,self.qnp), Poly(self.n,self.q,self.qnp), Poly(self.n,self.q,self.qnp)

        u.randomize(2)
        e1.randomize(0, domain=False, type=1, mu=self.mu, sigma=self.sigma)
        e2.randomize(0, domain=False, type=1, mu=self.mu, sigma=self.sigma)

        md = Poly(self.n,self.q,self.qnp)
        md.F = [(delta*x) % self.q for x in m.F]

        c0 = self.pk[0]*u + e1
        c0 = c0 + md
        c1 = self.pk[1]*u + e2

        return [c0,c1]
    #
    def Decryption(self, ct):
        """
        ct <- c1*s + c0
        ct <- floot(ct*(t/q))
        m <- [ct]_t
        """
        m = ct[1]*self.sk + ct[0]
        m.F = [((self.t*x)/self.q) for x in m.F]
        m = round(m)
        m = m % self.t
        mr = Poly(self.n,self.t,self.qnp)
        mr.F = m.F
        mr.inNTT = m.inNTT
        return mr
    def IntEncode(self,m): # integer encode
        mr = Poly(self.n,self.t)
        if m >0:
            mt = m
            for i in range(self.n):
                mr.F[i] = (mt % 2)
                mt      = (mt // 2)
        elif m<0:
            mt = -m
            for i in range(self.n):
                mr.F[i] = (self.t-(mt % 2)) % self.t
                mt      = (mt // 2)
        else:
            mr = mr
        return mr
    #
    def IntDecode(self,m): # integer decode
        mr = 0
        thr_ = 2 if(self.t == 2) else ((self.t+1)>>1)
        for i,c in enumerate(m.F):
            if c >= thr_:
                c_ = -(self.t-c)
            else:
                c_ = c
            mr = (mr + (c_ * pow(2,i)))
        return mr

def initialize(t, n, logq, q, psi, psiv, w, wv, T):
    # Determine mu, sigma (for discrete gaussian distribution)
    mu    = 0
    sigma = 0.5 * 3.2
    
    # Determine T, p (for relinearization and galois keys) based on noise analysis 
    p = q**3 + 1
    
    # Generate polynomial arithmetic tables
    w_table    = [1]*n
    wv_table   = [1]*n
    psi_table  = [1]*n
    psiv_table = [1]*n
    for i in range(1,n):
        w_table[i]    = ((w_table[i-1]   *w)    % q)
        wv_table[i]   = ((wv_table[i-1]  *wv)   % q)
        psi_table[i]  = ((psi_table[i-1] *psi)  % q)
        psiv_table[i] = ((psiv_table[i-1]*psiv) % q)
        
    qnp = [w_table,wv_table,psi_table,psiv_table]\
    # print(qnp)
    
    # Generate BFV evaluator
    Evaluator = BFV(n, q, t, mu, sigma, qnp)

    # Generate Keys
    Evaluator.SecretKeyGen()
    Evaluator.PublicKeyGen()
    Evaluator.EvalKeyGenV1(T)
    
    return Evaluator, qnp
    

def decrypt(Evaluator, n, q, qnp, n1, n2):
    # read ciphertext binary file
    # inputfile = open('ct_afterRelin_0.bin', mode='rb')
    inputfile = open('ctR0.bin', mode='rb')
    # inputfile = open('ct_afterRelin_0.bin', mode='rb')
    ctR0 = np.fromfile(inputfile, dtype=np.int64)
    inputfile.close

    # inputfile = open('ct_afterRelin_1.bin', mode='rb')
    inputfile = open('ctR1.bin', mode='rb')
    # inputfile = open('ct_afterRelin_1.bin', mode='rb')
    ctR1 = np.fromfile(inputfile, dtype=np.int64)
    inputfile.close
    
    # to generate incorrect results
    # ctR1 = np.random.rand(n)

    # format to Poly
    ct_C0 = Poly(n,q,qnp)
    ct_C0.F = [int(x) for x in ctR0]
    
    ct_C1 = Poly(n,q,qnp)
    ct_C1.F = [int(x) for x in ctR1]
    
    # for i in range(n):
    #     print(ct_C0.F[i], ct_C1.F[i])
    
    ct = [ct_C0, ct_C1]
    
    # decryption    
    mt = Evaluator.Decryption(ct)

    # integer decode
    nr = Evaluator.IntDecode(mt)
    
    # print result    
    if nr == n1 * n2:
        print("Correct decryption of cypertext of value 30")
    else:
        print("Incorrect decryption of cypertext of value 30")
        print("Decrypted value: {}".format(nr))
    

def main():
    
    if len(sys.argv) < 2:
        print("Specify mode: small, large")
        sys.exit(1)
    
    # dycryption relies on the seed
    random.seed(42)
    
    mode = sys.argv[1]
    if mode == "small":
        t, n, logq, T = 16, 16, 20, 256
        q, psi, psiv, w, wv = 1048193, 1007136, 501898, 182905, 908837
        n1, n2 = 5, 6
    elif mode == "large":
        # pre-computed parameters
        t, n, logq, T = 512, 512, 58, 256
        q, psi, psiv, w, wv = 288230376151690241, 70534235837001586, 145340914449191910, 198078549373310389, 92229011663445776
        n1, n2 = 5, 6

    Evaluator, qnp = initialize(t, n, logq, q, psi, psiv, w, wv, T)
        
    decrypt(Evaluator, n, q, qnp, n1, n2)  

if __name__ == "__main__":
    main()