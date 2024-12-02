//
//  Extensions.swift
//  ObjectRecognizer
//
//  Created by Shankeerthan on 2024-01-22.
//

import simd

extension SIMD4 {
    var xyz: SIMD3<Scalar> {
        self[SIMD3(0, 1, 2)]
    }
}

extension simd_float4x4 {
    var translation: SIMD3<Float> {
        get {
            SIMD3(columns.3.x, columns.3.y, columns.3.z)
        }
        set {
            self.columns.3 = [newValue.x, newValue.y, newValue.z, 1]
        }
    }
    
    var xAxis: SIMD3<Float> { columns.0.xyz }
    
    var yAxis: SIMD3<Float> { columns.1.xyz }
    
    var zAxis: SIMD3<Float> { columns.2.xyz }
    
}
