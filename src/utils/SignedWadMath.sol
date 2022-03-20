// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

function wadMul(int256 x, int256 y) pure returns (int256 z) {
    assembly {
        // Store x * y in z for now.
        z := mul(x, y)

        // Equivalent to require(x == 0 || (x * y) / x == y)
        if iszero(or(iszero(x), eq(sdiv(z, x), y))) {
            revert(0, 0)
        }

        // Scale the result down by 1e18.
        z := sdiv(z, 1000000000000000000)
    }
}

function wadDiv(int256 x, int256 y) pure returns (int256 z) {
    assembly {
        // Store x * y in z for now.
        z := mul(x, 1000000000000000000)

        // Equivalent to require(y != 0 && (x == 0 || (x * 1e18) / 1e18 == x))
        if iszero(and(iszero(iszero(y)), or(iszero(x), eq(sdiv(z, 1000000000000000000), x)))) {
            revert(0, 0)
        }

        // Divide z by y.
        z := sdiv(z, y)
    }
}

/// @dev NOT OVERFLOW SAFE! ONLY USE WHERE OVERFLOW IS NOT POSSIBLE!
function unsafeWadMul(int256 x, int256 y) pure returns (int256 z) {
    assembly {
        // Multiply x by y and divide by 1e18.
        z := sdiv(mul(x, y), 1000000000000000000)
    }
}

/// @dev Note: Will return 0 instead of reverting if y is zero.
/// @dev NOT OVERFLOW SAFE! ONLY USE WHERE OVERFLOW IS NOT POSSIBLE!
function unsafeWadDiv(int256 x, int256 y) pure returns (int256 z) {
    assembly {
        // Multiply x by 1e18 and divide it by y.
        z := sdiv(mul(x, 1000000000000000000), y)
    }
}

function wadExp(int256 x) pure returns (int256 z) {
    unchecked {
        // TODO: do we need to check x is less than the max of 130e18 ish
        // TODO: do we need to check x is greater than the min of int min
        // TODO: more assessment is needed whether we need the max check
        require(x < 130e18, "EXP_OVERFLOW");

        if (x < 0) {
            z = wadExp(-x); // Compute exp for x as a positive.

            assembly {
                // Divide it by 1e36, to get the inverse of the result.
                z := div(1000000000000000000000000000000000000, z)
            }

            return z; // Beyond this if statement we know x is positive.
        }

        z = 1; // Will multiply the result by this at the end. Default to 1 as a no-op, may be increased below.

        if (x >= 128000000000000000000) {
            x -= 128000000000000000000; // 2ˆ7 scaled by 1e18.

            // Because eˆ12800000000000000000 exp'd is too large to fit in 20 decimals, we'll store it unscaled.
            z = 38877084059945950922200000000000000000000000000000000000; // We'll multiply by this at the end.
        } else if (x >= 64000000000000000000) {
            x -= 64000000000000000000; // 2^6 scaled by 1e18.

            // Because eˆ64000000000000000000 exp'd is too large to fit in 20 decimals, we'll store it unscaled.
            z = 6235149080811616882910000000; // We'll multiply by this at the end, assuming x is large enough.
        }

        x *= 100; // Scale x to 20 decimals for extra precision.

        int256 precomputed = 1e20; // Will store the product of precomputed powers of 2 (which almost add up to x) exp'd.

        assembly {
            if iszero(lt(x, 3200000000000000000000)) {
                x := sub(x, 3200000000000000000000) // 2ˆ5 scaled by 1e18.

                // Multiplied by eˆ3200000000000000000000 scaled by 1e20 and divided by 1e20.
                precomputed := div(mul(precomputed, 7896296018268069516100000000000000), 100000000000000000000)
            }

            if iszero(lt(x, 1600000000000000000000)) {
                x := sub(x, 1600000000000000000000) // 2ˆ4 scaled by 1e18.

                // Multiplied by eˆ16000000000000000000 scaled by 1e20 and divided by 1e20.
                precomputed := div(mul(precomputed, 888611052050787263676000000), 100000000000000000000)
            }

            if iszero(lt(x, 800000000000000000000)) {
                x := sub(x, 800000000000000000000) // 2ˆ3 scaled by 1e18.

                // Multiplied by eˆ8000000000000000000 scaled by 1e20 and divided by 1e20.
                precomputed := div(mul(precomputed, 2980957987041728274740004), 100000000000000000000)
            }

            if iszero(lt(x, 400000000000000000000)) {
                x := sub(x, 400000000000000000000) // 2ˆ2 scaled by 1e18.

                // Multiplied by eˆ4000000000000000000 scaled by 1e20 and divided by 1e20.
                precomputed := div(mul(precomputed, 5459815003314423907810), 100000000000000000000)
            }

            if iszero(lt(x, 200000000000000000000)) {
                x := sub(x, 200000000000000000000) // 2ˆ1 scaled by 1e18.

                // Multiplied by eˆ2000000000000000000 scaled by 1e20 and divided by 1e20.
                precomputed := div(mul(precomputed, 738905609893065022723), 100000000000000000000)
            }

            if iszero(lt(x, 100000000000000000000)) {
                x := sub(x, 100000000000000000000) // 2ˆ0 scaled by 1e18.

                // Multiplied by eˆ1000000000000000000 scaled by 1e20 and divided by 1e20.
                precomputed := div(mul(precomputed, 271828182845904523536), 100000000000000000000)
            }

            if iszero(lt(x, 50000000000000000000)) {
                x := sub(x, 50000000000000000000) // 2ˆ-1 scaled by 1e18.

                // Multiplied by eˆ5000000000000000000 scaled by 1e20 and divided by 1e20.
                precomputed := div(mul(precomputed, 164872127070012814685), 100000000000000000000)
            }

            if iszero(lt(x, 25000000000000000000)) {
                x := sub(x, 25000000000000000000) // 2ˆ-2 scaled by 1e18.

                // Multiplied by eˆ250000000000000000 scaled by 1e20 and divided by 1e20.
                precomputed := div(mul(precomputed, 128402541668774148407), 100000000000000000000)
            }
        }

        // We'll be using the Taylor series for e^x which looks like: 1 + x + (x^2 / 2!) + ... + (x^n / n!)
        // to approximate the exp of the remaining value x not covered by the precomputed product above.
        int256 term = x; // Will track each term in the Taylor series, beginning with x.
        int256 series = 1e20 + term; // The Taylor series begins with 1 plus the first term, x.

        assembly {
            term := div(mul(term, x), 200000000000000000000) // Equal to dividing x^2 by 2e20 as the first term was just x.
            series := add(series, term)

            term := div(mul(term, x), 300000000000000000000) // Equal to dividing x^3 by 6e20 (3!) as the last term was x divided by 2e20.
            series := add(series, term)

            term := div(mul(term, x), 400000000000000000000) // Equal to dividing x^4 by 24e20 (4!) as the last term was x divided by 6e20.
            series := add(series, term)

            term := div(mul(term, x), 500000000000000000000) // Equal to dividing x^5 by 120e20 (5!) as the last term was x divided by 24e20.
            series := add(series, term)

            term := div(mul(term, x), 600000000000000000000) // Equal to dividing x^6 by 720e20 (6!) as the last term was x divided by 120e20.
            series := add(series, term)

            term := div(mul(term, x), 700000000000000000000) // Equal to dividing x^7 by 5040e20 (7!) as the last term was x divided by 720e20.
            series := add(series, term)

            term := div(mul(term, x), 800000000000000000000) // Equal to dividing x^8 by 40320e20 (8!) as the last term was x divided by 5040e20.
            series := add(series, term)

            term := div(mul(term, x), 900000000000000000000) // Equal to dividing x^9 by 362880e20 (9!) as the last term was x divided by 40320e20.
            series := add(series, term)

            term := div(mul(term, x), 1000000000000000000000) // Equal to dividing x^10 by 3628800e20 (10!) as the last term was x divided by 362880e20.
            series := add(series, term)

            term := div(mul(term, x), 1100000000000000000000) // Equal to dividing x^11 by 39916800e20 (11!) as the last term was x divided by 3628800e20.
            series := add(series, term)

            term := div(mul(term, x), 1200000000000000000000) // Equal to dividing x^12 by 479001600e20 (12!) as the last term was x divided by 39916800e20.
            series := add(series, term)
        }

        // Since e^x * e^y equals e^(x+y) we multiply our Taylor series and precomputed exp'd powers of 2 to get the final result scaled by 1e20.
        return (((series * precomputed) / 1e20) * z) / 100; // We divide the final result by 100 to scale it back down to 18 decimals of precision.
    }
}

function wadLn(int256 a) pure returns (int256 ret) {
    unchecked {
        // The real natural logarithm is not defined for negative numbers or zero.
        // TODO: did i do this conversion to <= from < properly? should i have added or subtracted one lol

        bool ln36;

        assembly {
            ln36 := and(gt(a, 90000000000000000), lt(a, 1100000000000000000))
        }

        if (ln36) {
            // Since ln(1) = 0, a value of x close to one will yield a very small result, which makes using 36 digits
            // worthwhile.

            // First, we transform x to a 36 digit fixed point value.
            a *= 1e18;

            // We will use the following Taylor expansion, which converges very rapidly. Let z = (x - 1) / (x + 1).
            // ln(x) = 2 * (z + z^3 / 3 + z^5 / 5 + z^7 / 7 + ... + z^(2 * n + 1) / (2 * n + 1))

            // Recall that 36 digit fixed point division requires multiplying by ONE_36, and multiplication requires
            // division by ONE_36.

            int256 z;
            assembly {
                z := sdiv(
                    mul(sub(a, 1000000000000000000000000000000000000), 1000000000000000000000000000000000000),
                    add(a, 1000000000000000000000000000000000000)
                )
            }

            int256 z_squared;
            assembly {
                z_squared := sdiv(mul(z, z), 1000000000000000000000000000000000000)
            }

            // num is the numerator of the series: the z^(2 * n + 1) term
            int256 num = z;

            // seriesSum holds the accumulated sum of each term in the series, starting with the initial z
            int256 seriesSum = num;

            // In each step, the numerator is multiplied by z^2
            assembly {
                num := sdiv(mul(num, z_squared), 1000000000000000000000000000000000000)
                seriesSum := add(seriesSum, sdiv(num, 3))

                num := sdiv(mul(num, z_squared), 1000000000000000000000000000000000000)
                seriesSum := add(seriesSum, sdiv(num, 5))

                num := sdiv(mul(num, z_squared), 1000000000000000000000000000000000000)
                seriesSum := add(seriesSum, sdiv(num, 7))

                num := sdiv(mul(num, z_squared), 1000000000000000000000000000000000000)
                seriesSum := add(seriesSum, sdiv(num, 9))

                num := sdiv(mul(num, z_squared), 1000000000000000000000000000000000000)
                seriesSum := add(seriesSum, sdiv(num, 11))

                num := sdiv(mul(num, z_squared), 1000000000000000000000000000000000000)
                seriesSum := add(seriesSum, sdiv(num, 13))

                num := sdiv(mul(num, z_squared), 1000000000000000000000000000000000000)
                seriesSum := add(seriesSum, sdiv(num, 15))
            }

            // 8 Taylor terms are sufficient for 36 decimal precision.
            assembly {
                ret := sdiv(seriesSum, 500000000000000000)
            }
        } else {
            // TODO: did i transform this from < to <= right?
            if (a <= 999999999999999999) {
                // Since ln(a^k) = k * ln(a), we can compute ln(a) as ln(a) = ln((1/a)^(-1)) = - ln((1/a)). If a is less
                // than one, 1/a will be greater than one, and this if statement will not be entered in the recursive call.
                // Fixed point division requires multiplying by ONE_18.
                return -wadLn(1e36 / a);
            }

            // First, we use the fact that ln^(a * b) = ln(a) + ln(b) to decompose ln(a) into a sum of powers of two, which
            // we call x_n, where x_n == 2^(7 - n), which are the natural logarithm of precomputed quantities a_n (that is,
            // ln(a_n) = x_n). We choose the first x_n, x0, to equal 2^7 because the exponential of all larger powers cannot
            // be represented as 18 fixed point decimal numbers in 256 bits, and are therefore larger than a.
            // At the end of this process we will have the sum of all x_n = ln(a_n) that apply, and the remainder of this
            // decomposition, which will be lower than the smallest a_n.
            // ln(a) = k_0 * x_0 + k_1 * x_1 + ... + k_n * x_n + ln(remainder), where each k_n equals either 0 or 1.
            // We mutate a by subtracting a_n, making it the remainder of the decomposition.

            // For reasons related to how `exp` works, the first two a_n (e^(2^7) and e^(2^6)) are not stored as fixed point
            // numbers with 18 decimals, but instead as plain integers with 0 decimals, so we need to multiply them by
            // ONE_18 to convert them to fixed point.
            // For each a_n, we test if that term is present in the decomposition (if a is larger than it), and if so divide
            // by it and compute the accumulated sum.

            int256 sum = 0;

            assembly {
                if iszero(lt(a, 38877084059945950922200000000000000000000000000000000000000000000000000000)) {
                    a := div(a, 38877084059945950922200000000000000000000000000000000000)
                    sum := add(sum, 128000000000000000000)
                }

                if iszero(lt(a, 6235149080811616882910000000000000000000000000)) {
                    a := div(a, 6235149080811616882910000000)
                    sum := add(sum, 64000000000000000000)
                }
            }

            // All other a_n and x_n are stored as 20 digit fixed point numbers, so we convert the sum and a to this format.
            sum *= 100;
            a *= 100;

            assembly {
                if iszero(lt(a, 7896296018268069516100000000000000)) {
                    a := div(mul(a, 100000000000000000000), 7896296018268069516100000000000000)
                    sum := add(sum, 3200000000000000000000)
                }

                if iszero(lt(a, 888611052050787263676000000)) {
                    a := div(mul(a, 100000000000000000000), 888611052050787263676000000)
                    sum := add(sum, 1600000000000000000000)
                }

                if iszero(lt(a, 298095798704172827474000)) {
                    a := div(mul(a, 100000000000000000000), 298095798704172827474000)
                    sum := add(sum, 800000000000000000000)
                }

                if iszero(lt(a, 5459815003314423907810)) {
                    a := div(mul(a, 100000000000000000000), 5459815003314423907810)
                    sum := add(sum, 400000000000000000000)
                }

                if iszero(lt(a, 738905609893065022723)) {
                    a := div(mul(a, 100000000000000000000), 738905609893065022723)
                    sum := add(sum, 200000000000000000000)
                }

                if iszero(lt(a, 271828182845904523536)) {
                    a := div(mul(a, 100000000000000000000), 271828182845904523536)
                    sum := add(sum, 100000000000000000000)
                }

                if iszero(lt(a, 164872127070012814685)) {
                    a := div(mul(a, 100000000000000000000), 164872127070012814685)
                    sum := add(sum, 50000000000000000000)
                }

                if iszero(lt(a, 128402541668774148407)) {
                    a := div(mul(a, 100000000000000000000), 128402541668774148407)
                    sum := add(sum, 25000000000000000000)
                }

                if iszero(lt(a, 113314845306682631683)) {
                    a := div(mul(a, 100000000000000000000), 113314845306682631683)
                    sum := add(sum, 12500000000000000000)
                }

                if iszero(lt(a, 106449445891785942956)) {
                    a := div(mul(a, 100000000000000000000), 106449445891785942956)
                    sum := add(sum, 6250000000000000000)
                }
            }

            // a is now a small number (smaller than a_11, which roughly equals 1.06). This means we can use a Taylor series
            // that converges rapidly for values of `a` close to one - the same one used in ln_36.
            // Let z = (a - 1) / (a + 1).
            // ln(a) = 2 * (z + z^3 / 3 + z^5 / 5 + z^7 / 7 + ... + z^(2 * n + 1) / (2 * n + 1))

            // Recall that 20 digit fixed point division requires multiplying by ONE_20, and multiplication requires
            // division by ONE_20.
            int256 z;
            assembly {
                z := div(mul(sub(a, 100000000000000000000), 100000000000000000000), add(a, 100000000000000000000))
            }

            int256 z_squared;
            assembly {
                z_squared := div(mul(z, z), 100000000000000000000)
            }

            // num is the numerator of the series: the z^(2 * n + 1) term
            int256 num = z;

            // seriesSum holds the accumulated sum of each term in the series, starting with the initial z
            int256 seriesSum = num;

            // In each step, the numerator is multiplied by z^2

            assembly {
                num := div(mul(num, z_squared), 100000000000000000000)
                seriesSum := add(seriesSum, div(num, 3))

                num := div(mul(num, z_squared), 100000000000000000000)
                seriesSum := add(seriesSum, div(num, 5))

                num := div(mul(num, z_squared), 100000000000000000000)
                seriesSum := add(seriesSum, div(num, 7))

                num := div(mul(num, z_squared), 100000000000000000000)
                seriesSum := add(seriesSum, div(num, 9))

                num := div(mul(num, z_squared), 100000000000000000000)
                seriesSum := add(seriesSum, div(num, 11))
            }

            // 6 Taylor terms are sufficient for 36 decimal precision.

            // Finally, we multiply by 2 (non fixed point) to compute ln(remainder)

            seriesSum *= 2;

            // We now have the sum of all x_n present, and the Taylor approximation of the logarithm of the remainder (both
            // with 20 decimals). All that remains is to sum these two, and then drop two digits to return a 18 decimal
            // value.

            assembly {
                ret := div(add(sum, seriesSum), 100)
            }
        }
    }
}
