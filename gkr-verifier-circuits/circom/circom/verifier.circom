pragma circom 2.1.0;
include "./poly/univariate.circom"
include "./poly/multivariate.circom"
include "./sumcheck/sumcheckVerify.circom"

template VerifyLayer() {

}

template VerifyGKR(meta) {
    // metadata of circuit
    // 0 --> d
    // 1 --> largest_k
    // 2 --> k_i(0)
    // 3 --> # of terms of D
    // 4 --> largest # of terms among sumcheck proofs (highest degree)
    // 5 --> largest # of terms among q
    // 6 --> # of terms in w_d
    // 7 --> k_i(d - 1)
    // 8 --> largest # of terms among add_i
    // 9 --> largest # of terms among mult_i
    var d = meta[0];
    var largest_k = meta[1];

    signal input sumcheckProof[d - 1][2 * largest_k - 1][meta[4]];
    signal input sumcheckr[d - 1][2 * largest_k];
    signal input q[d - 1][meta[5]];
    signal input f[d - 1];
    signal input D[meta[3]][meta[2] + 1];
    signal input z[d][largest_k];
    signal input r[d - 1];

    signal input inputFunc[meta[6]][meta[7]];
    signal input add[d - 1][meta[8]][3 * largest_k];
    signal input mult[d - 1][meta[9]][3 * largest_k];

    signal output isValid;

    component m[d];

    m[0] = evalMultivariate(meta[3], meta[2]);
    for (var i = 0; i < v; i++) {
        m[0].x[i] <== z[0][i];
    }
    for (var i = 0; i < meta[3]; i++) {
        for (var j = 0; j < meta[2] + 1; j++) {
            m[0].terms[i][j] <== D[i][j];
        }
    }

    component sumcheckVerifier[d - 1];
    component qZero[d - 1];
    component qOne[d - 1];

    signal modifiedF[d - 1];
    component addR[d - 1];
    component multR[d - 1];

    component inputValue = evalMultivariate(meta[6], meta[7]);

    for (var i = 0; i < d - 1; i++) {
        sumcheckVerifier[i] = SumcheckVerify(2 * largest_k);
        sumcheckVerifier[i].claim <== m[i].result;
        for (var j = 0; j < 2 * largest_k - 1; j++) {
            sumcheckVerifier[i].r[j] <== sumcheckr[i][j];
            for (var k = 0; k < meta[4]; k++) {
                sumcheckVerifier[i][j][k] <== sumcheckProof[i][j][k];
            }
        }

        sumcheckVerifier[i].isValid === 1;

        qZero[i] = evalUnivariate(meta[5]);
        qOne[i] = evalUnivariate(meta[5]);

        qZero.x <== 0;
        qOne.x <== 0;

        for (var j = 0; j < meta[5]; j++) {
            qZero[i].coeffs[j] <== q[i][j];
            qOne[i].coeffs[j] <== q[i][j];
        }

        addR[i] = evalMultivariate(meta[8], 3 * largest_k);
        multR[i] = evalMultivariate(meta[8], 3 * largest_k);

        for (var j = 0; j < meta[8]; j++) {
            for (var k = 0; k < 3 * largest_k; k++) {
                addR[i].terms[j][k] <== add[i][j][k];
                if (k < largest_k) {
                    addR[i].x[k] <== z[i][k];
                } else {
                    addR[i].x[k] <== sumcheckr[i][k];
                }
            }
        }
        for (var j = 0; j < meta[9]; j++) {
            for (var k = 0; k < 3 * largest_k; k++) {
                multR[i].terms[j][k] <== mult[i][j][k];
                if (k < largest_k) {
                    multR[i].x[k] <== z[i][k];
                } else {
                    multR[i].x[k] <== sumcheckr[i][k];
                }
            }
        }
        modifiedF[i] <== addR[i].result * (qZero[i].result + qOne[i].result) + multR[i].result * qOne[i].result * qZero[i].result;
        modifiedF[i] === f[i];

        m[i + 1] = evalUnivariate(meta[5]);
        for (var j = 0; j < meta[5]; j++) {
            m[i + 1].coeffs[j] <== q[i][j];
        }
        m[i + 1].x <== r[i];
    }

    for (var i = 0; i < meta[6]; i++) {
        for (var j = 0; j < meta[7]; j++) {
            inputValue.terms[i][j] <== inputFunc[i][j];
            inputValue.x[j] <== z[d - 1][j];
        }
    }
    m[d - 1].result === inputValue.result

    isValid <== 1;
}
