"""
Mathematical functions for PyScript
Provides mathematical operations and constants.
"""

# Constants
pi = 3.141592653589793
e = 2.718281828459045
tau = 6.283185307179586
inf = float('inf')
nan = float('nan')

# Number theory functions
def ceil(x):
    """Return ceiling of x"""
    import math
    return math.ceil(x)

def floor(x):
    """Return floor of x"""
    import math
    return math.floor(x)

def trunc(x):
    """Truncate x to integer"""
    import math
    return math.trunc(x)

# Power and logarithmic functions
def exp(x):
    """Exponential function"""
    import math
    return math.exp(x)

def expm1(x):
    """exp(x) - 1"""
    import math
    return math.expm1(x)

def log(x, base=None):
    """Natural logarithm"""
    import math
    if base is None:
        return math.log(x)
    return math.log(x, base)

def log1p(x):
    """Natural logarithm of 1+x"""
    import math
    return math.log1p(x)

def log2(x):
    """Base-2 logarithm"""
    import math
    return math.log2(x)

def log10(x):
    """Base-10 logarithm"""
    import math
    return math.log10(x)

def pow(x, y):
    """x raised to y"""
    import math
    return math.pow(x, y)

def sqrt(x):
    """Square root"""
    import math
    return math.sqrt(x)

# Trigonometric functions
def acos(x):
    """Arc cosine"""
    import math
    return math.acos(x)

def asin(x):
    """Arc sine"""
    import math
    return math.asin(x)

def atan(x):
    """Arc tangent"""
    import math
    return math.atan(x)

def atan2(y, x):
    """Arc tangent of y/x"""
    import math
    return math.atan2(y, x)

def cos(x):
    """Cosine"""
    import math
    return math.cos(x)

def hypot(x, y):
    """Euclidean norm"""
    import math
    return math.hypot(x, y)

def sin(x):
    """Sine"""
    import math
    return math.sin(x)

def tan(x):
    """Tangent"""
    import math
    return math.tan(x)

# Hyperbolic functions
def acosh(x):
    """Inverse hyperbolic cosine"""
    import math
    return math.acosh(x)

def asinh(x):
    """Inverse hyperbolic sine"""
    import math
    return math.asinh(x)

def atanh(x):
    """Inverse hyperbolic tangent"""
    import math
    return math.atanh(x)

def cosh(x):
    """Hyperbolic cosine"""
    import math
    return math.cosh(x)

def sinh(x):
    """Hyperbolic sine"""
    import math
    return math.sinh(x)

def tanh(x):
    """Hyperbolic tangent"""
    import math
    return math.tanh(x)

# Angular conversion
def degrees(x):
    """Convert radians to degrees"""
    import math
    return math.degrees(x)

def radians(x):
    """Convert degrees to radians"""
    import math
    return math.radians(x)

# Special functions
def erf(x):
    """Error function"""
    import math
    return math.erf(x)

def erfc(x):
    """Complementary error function"""
    import math
    return math.erfc(x)

def gamma(x):
    """Gamma function"""
    import math
    return math.gamma(x)

def lgamma(x):
    """Natural logarithm of gamma function"""
    import math
    return math.lgamma(x)

# Constants from math module
def get_constants():
    """Get all math constants"""
    return {
        'pi': pi,
        'e': e,
        'tau': tau,
        'inf': inf,
        'nan': nan
    }