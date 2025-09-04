"""
Random number generation for PyScript
Provides functions for generating random numbers.
"""

import random
import time

# Seed the random number generator
def seed(a=None):
    """Initialize random number generator"""
    if a is None:
        a = int(time.time() * 1000)
    random.seed(a)
    return a

# Random integers
def randrange(start, stop=None, step=1):
    """Choose random item from range"""
    if stop is None:
        stop = start
        start = 0
    return random.randrange(start, stop, step)

def randint(a, b):
    """Random integer in range [a, b]"""
    return random.randint(a, b)

# Random floating point numbers
def random():
    """Random float in [0.0, 1.0)"""
    return random.random()

def uniform(a, b):
    """Random float in [a, b]"""
    return random.uniform(a, b)

# Random choices from sequences
def choice(seq):
    """Choose random element from sequence"""
    return random.choice(seq)

def choices(population, weights=None, cum_weights=None, k=1):
    """Choose k elements from population with replacement"""
    return random.choices(population, weights=weights, cum_weights=cum_weights, k=k)

def shuffle(seq):
    """Shuffle sequence in place"""
    random.shuffle(seq)
    return seq

def sample(population, k):
    """Choose k unique elements from population"""
    return random.sample(population, k)

# Random bytes
def getrandbits(k):
    """Generate k random bits"""
    return random.getrandbits(k)

# Normal distributions
def normalvariate(mu, sigma):
    """Normal distribution"""
    return random.normalvariate(mu, sigma)

def gauss(mu, sigma):
    """Gaussian distribution"""
    return random.gauss(mu, sigma)

def lognormvariate(mu, sigma):
    """Log normal distribution"""
    return random.lognormvariate(mu, sigma)

# Exponential distributions
def expovariate(lambd):
    """Exponential distribution"""
    return random.expovariate(lambd)

def vonmisesvariate(mu, kappa):
    """Von Mises distribution"""
    return random.vonmisesvariate(mu, kappa)

# Angular distributions
def triangular(low, high, mode=None):
    """Triangular distribution"""
    if mode is None:
        mode = (low + high) / 2
    return random.triangular(low, high, mode)

def betavariate(alpha, beta):
    """Beta distribution"""
    return random.betavariate(alpha, beta)

def gammavariate(alpha, beta):
    """Gamma distribution"""
    return random.gammavariate(alpha, beta)

# Pareto distribution
def paretovariate(alpha):
    """Pareto distribution"""
    return random.paretovariate(alpha)

# Weibull distribution
def weibullvariate(alpha, beta):
    """Weibull distribution"""
    return random.weibullvariate(alpha, beta)