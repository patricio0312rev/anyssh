@testable import AnySSHCore

extension KeyFixtures {
    static let rsaPEM = KeyFixture(
        name: "RSA PEM plain",
        text: """
            -----BEGIN RSA PRIVATE KEY-----
            MIIEpAIBAAKCAQEAl6I7Zex+HkTBPDb+x9eN3pSQWUt7fgQ8e+r9FCAJS2DjIcpg
            ljPtpN3AqX2wMBYN74oCd+6UVZGs+EQ2wmFNykkIOz15T+tmU15G7mtmq8v+PaY3
            rZ3EECDJvkEfQ05KQwTB2JMHoAK+QD+UmL4DSeVi4RszngrJizZ2/U6kAhuARPB0
            0vXqLhuF3kTWtqZsREz6srTec0I8Vi8Vb9q6lO9eHYAyOeSpDQWp/RJcpR9MH76l
            YCDXeq7gvFovQCJrWVeAolo2g3XAPvwxXxGraUbXH6cv2gO0m75GjqnxoSCT5jKJ
            c/9C/i1/3j660JzPND1zKsaEXXX3LGKQ4n2ggwIDAQABAoIBACmvpwa5Ql7N5hXI
            xLhp8Q2s6BY0YyncvkgO7S54NDXt1+N1QKJqej2l3Q57iFFf7srYtR8FjvALUXMb
            Rbagi4M+Gq42k0A+Ze4rb/KhwiMevLF0HcB0K++HJA9S1eZqAo50I1qH6UO7HVSK
            Zi6rpjnNfyaFlOYw7wF/oqy2zu3o90BhAY43U3E+zQMBjhtTIlt4U3X8aXEI8xaI
            AhgQnaScCjcfjX5H6Hkt4/d5ZjzjkurThrGZodezei/OSDEIC1r8r/1tOFtiCHZ1
            pUF/46Ew62/NOT+3BLlHjraYMu1GhNvlXQpyGaGh+QjodqlBtsfJG+bAD47qso62
            882kiZECgYEAxjwQuWqPa5pLk/cuAb/6sHaWJCR6kK/GlrakcetlV4MNkZEC1+6q
            ajI+bRPSwtQVPlNLKNhRxocYbGvOQx96gIO4/iOAfm6hIEkXUCboOoPC/edE9DCj
            9VVObWptFOrux30y+TnGwJMO7OTNm4jImktypJ9zpyx8VQM/1DjrgssCgYEAw9HT
            TN/XXBzo2Wx1i9F/R1445Gs/WyRWvrWJER+CVdo7DAgJ2tQ8v/C5x7Y0iUmhzoHH
            DiP5IddOwiHZi4u+i+QKXn0g0q+WWZAoUZvkMx2TPe+q+z1iIMWPHzP317QV1Wmi
            cJZOVURDlBzfHmAMs0ofxAR7kV+a01iAJwkFSikCgYBCW4T1rFgKGwJFq65443zV
            aTzlKFjm6hA+DzGI+NVZsALwwWwEQF5HYj5HYSViFoBt9o/oQlFNdZeVY5kOGxF0
            x6M7X0L6D6pcFlt5dyyxub2iJLKOU2HvE/lG4yNUpzf7C0vu5YpEmHWckxLIh8cu
            7yaXONEMGvYbtxS8w7kCdQKBgQCuB1iGxZicIIVAVgfRjwpS3wYo2refxJfjPWrn
            cN1gd2ZqtuorNNwYqVQyjVf7exj2cpf5lTbgQH2aQoMYZcWehbhBaWs2Ux6H0npC
            rQ0N8IbfUJTgXBlNjsY3sPPfHAkbdZoL/Uj4toZop5ATasFexc2dY25+MD1k/w5F
            otq0oQKBgQCLVjzqNgwsjkMZpaanXGLOZVicldMyd5ky3HmMdYX470/3fiPUlrB+
            Cf93qvY1NNn6A3SG01b5ww8CymAvsKdM4EcnjU+hglUySsQVuvyZp6AsNfZ1MX0W
            NRdZ7lTJsnWF4sTpBr+3F8R5QhTLqkH2zLTdFFvFYTr65b27Ufg7Xg==
            -----END RSA PRIVATE KEY-----
            """,
        format: .rsaPKCS1,
        algorithm: .rsa,
        isEncrypted: false,
        bitCount: 2048,
        fingerprint: "SHA256:wdhH1xSlsULr2cVrlQlyErEn6PfeLe6kanZFC3J0KHU"
    )

    static let rsaPEMEncrypted = KeyFixture(
        name: "RSA PEM encrypted",
        text: """
            -----BEGIN RSA PRIVATE KEY-----
            Proc-Type: 4,ENCRYPTED
            DEK-Info: AES-128-CBC,BF26DB9F4777423DCFFDEE9AD8645DE2

            7brAJQztFF000qroIIZNxlpG/aJQ+rgZgGLqaRFhdG4fyb6XQ3dypOJ28XkBKHI/
            9jffOKgVcUrX8+wI2menEQM0SUsLTMeJqUxbATU4JdKj/HATXLafm9RLVZCmVNzW
            wgN3cUP+xJ23Es8udsfh4+gzCBYH8/90WhS8mz0IG/KfMxkdczc10cftMb0gMJW9
            97YmGS4R/c/TVi6GUILRtrxs5B8QFDlxVNWiq+QU24s0Bl/fe0ekDJN0dLCcP4l6
            H5e0zolDODDTjSvJUGfGm3fw0TsyYjQquMTHf1RPkeQlqHfQ5tn9JJjaJiZSk6ho
            ulTYKa0oqBpvH7fPr7xyIo7tWzFoPGzTXW8Syv+0u5OaKia2DpWVoul2YlS8FUgA
            uYAIXnBwj7ZohsXuv8dPSSEHe//f18sNLDd0AuosaJvmqS1Y44gds3lthx+S2Oiq
            8iHObosRXYR+JDdt7I46GvS2XZUFYyY3SvifYFotLMRYJ08l36GSDUEM/ZKMayV5
            PcB2IBU/UCWuFbgDRfFWkz7r1yBBNs5lh40lFPCHMceNVBjpu7EakPs/qhF8nTXG
            updeFIoYYaSPP1x5QG7LAsCN6d+v64AJVQmqpfsOI5VMnFDXSHTASX9b/ltkMR+x
            0zZlPuGPRfoMiiWliu9kEEcFcwefIlsCO2V2LqUvLKSmTFEcDsU08hgeI8kssSct
            EJZ98nzDbw5d4ONDZKkQmj9pMadOyErp7La/rOprWZxc6kLgRsTyiedz+hnIik8J
            CtqqWjrgnQyHIwa4HdqhAvwQplyaloKmK0KeG0l7/MxW8bU6pyWI1Dx29+1lerei
            WH9u3ImewtHuXdhhVAwQpTi6cBo7XjNpaD5TE+SVJN8lEbb0xzALnwXmL4scpK/O
            m3Y+B/uQKiycetoyRkYYd5EMuOUCTSZcWejFiPIlrR2b7r6dfGwomle+d/zGE0hR
            yCzaHYzOHhLw11Mip6oPOqmKai0d9DlmSF5C2l+o7QSCKB/ndp78RTJrh1UDP4gF
            9AkHeV4mlXue0WIgOH0dGnnmTfUIkRr/eZ/LT5cATqPuhuCsown8NZGyAj3YFaT4
            dOwZV/pD9XXMShVQZqLKgdub48rYG6AnpNIbWLg5ElF+UqwDjuPrMDGa93qzsAgj
            WXhLr7hc0Kh2ejInqfSuQqLlvRFLUx/nYj7Vr94in78l87cgJ+tEP5GgT+EDUcoI
            e0FNhA/TEoSeK9FqpGoIkwEgv3MuruJgniSOFao9IRZZv+Qy0dLb8V2CfNmNBqMO
            As3PbgE8ib80RcDZZdE90hr5OvIDhF+4Rxyya3nboMgSZwGTRA9SenfjpQ+u6f6i
            zaJuvZD0Gf8mhoXw6ERpME60lP/iGGDvDjMdkSMepwZf1af3mBvjiEy4c2FvNFOg
            tJZP0UvBLAaDmA16WZJa7AKzymbVO6b2tj0KQA1uCj/DqjKZ8QB2zmN57qHtEWI3
            CjBF90rnuf95gsqVv5ceJ3AtdDdCPjFqXdS5E8Fp8KsEXBkM+OKipdvzSpfFctSk
            Gd2q9beEz0NJf5AR6D/qzJbJKoucASZZxM08NBPRxFNPWRHDOWCKvs1mMHLP4Pq+
            -----END RSA PRIVATE KEY-----
            """,
        format: .rsaPKCS1,
        algorithm: .rsa,
        isEncrypted: true
    )

    static let rsaPKCS8 = KeyFixture(
        name: "RSA PKCS#8 plain",
        text: """
            -----BEGIN PRIVATE KEY-----
            MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQCXojtl7H4eRME8
            Nv7H143elJBZS3t+BDx76v0UIAlLYOMhymCWM+2k3cCpfbAwFg3vigJ37pRVkaz4
            RDbCYU3KSQg7PXlP62ZTXkbua2ary/49pjetncQQIMm+QR9DTkpDBMHYkwegAr5A
            P5SYvgNJ5WLhGzOeCsmLNnb9TqQCG4BE8HTS9eouG4XeRNa2pmxETPqytN5zQjxW
            LxVv2rqU714dgDI55KkNBan9ElylH0wfvqVgINd6ruC8Wi9AImtZV4CiWjaDdcA+
            /DFfEatpRtcfpy/aA7SbvkaOqfGhIJPmMolz/0L+LX/ePrrQnM80PXMqxoRddfcs
            YpDifaCDAgMBAAECggEAKa+nBrlCXs3mFcjEuGnxDazoFjRjKdy+SA7tLng0Ne3X
            43VAomp6PaXdDnuIUV/uyti1HwWO8AtRcxtFtqCLgz4arjaTQD5l7itv8qHCIx68
            sXQdwHQr74ckD1LV5moCjnQjWofpQ7sdVIpmLqumOc1/JoWU5jDvAX+irLbO7ej3
            QGEBjjdTcT7NAwGOG1MiW3hTdfxpcQjzFogCGBCdpJwKNx+NfkfoeS3j93lmPOOS
            6tOGsZmh17N6L85IMQgLWvyv/W04W2IIdnWlQX/joTDrb805P7cEuUeOtpgy7UaE
            2+VdCnIZoaH5COh2qUG2x8kb5sAPjuqyjrbzzaSJkQKBgQDGPBC5ao9rmkuT9y4B
            v/qwdpYkJHqQr8aWtqRx62VXgw2RkQLX7qpqMj5tE9LC1BU+U0so2FHGhxhsa85D
            H3qAg7j+I4B+bqEgSRdQJug6g8L950T0MKP1VU5tam0U6u7HfTL5OcbAkw7s5M2b
            iMiaS3Kkn3OnLHxVAz/UOOuCywKBgQDD0dNM39dcHOjZbHWL0X9HXjjkaz9bJFa+
            tYkRH4JV2jsMCAna1Dy/8LnHtjSJSaHOgccOI/kh107CIdmLi76L5ApefSDSr5ZZ
            kChRm+QzHZM976r7PWIgxY8fM/fXtBXVaaJwlk5VREOUHN8eYAyzSh/EBHuRX5rT
            WIAnCQVKKQKBgEJbhPWsWAobAkWrrnjjfNVpPOUoWObqED4PMYj41VmwAvDBbARA
            XkdiPkdhJWIWgG32j+hCUU11l5VjmQ4bEXTHoztfQvoPqlwWW3l3LLG5vaIkso5T
            Ye8T+UbjI1SnN/sLS+7likSYdZyTEsiHxy7vJpc40Qwa9hu3FLzDuQJ1AoGBAK4H
            WIbFmJwghUBWB9GPClLfBijat5/El+M9audw3WB3Zmq26is03BipVDKNV/t7GPZy
            l/mVNuBAfZpCgxhlxZ6FuEFpazZTHofSekKtDQ3wht9QlOBcGU2Oxjew898cCRt1
            mgv9SPi2hminkBNqwV7FzZ1jbn4wPWT/DkWi2rShAoGBAItWPOo2DCyOQxmlpqdc
            Ys5lWJyV0zJ3mTLceYx1hfjvT/d+I9SWsH4J/3eq9jU02foDdIbTVvnDDwLKYC+w
            p0zgRyeNT6GCVTJKxBW6/JmnoCw19nUxfRY1F1nuVMmydYXixOkGv7cXxHlCFMuq
            QfbMtN0UW8VhOvrlvbtR+Dte
            -----END PRIVATE KEY-----
            """,
        format: .pkcs8,
        algorithm: .rsa,
        isEncrypted: false,
        bitCount: 2048,
        fingerprint: "SHA256:wdhH1xSlsULr2cVrlQlyErEn6PfeLe6kanZFC3J0KHU"
    )

    static let rsaPKCS8Encrypted = KeyFixture(
        name: "RSA PKCS#8 encrypted",
        text: """
            -----BEGIN ENCRYPTED PRIVATE KEY-----
            MIIFNTBfBgkqhkiG9w0BBQ0wUjAxBgkqhkiG9w0BBQwwJAQQIF5FJ5mm/NqGIjts
            eob0ZAICCAAwDAYIKoZIhvcNAgkFADAdBglghkgBZQMEASoEEPnCqQxSxywDDCox
            LU9LPkkEggTQ+oUyJUkBQKGp3Pz8cGHHydNjYjAOxFtQIUt6l/3wQesPoesIKkjO
            UZw7utIOSDsRsIt9D46RNJ/74KGkUFAoflUvDJvHH83PKJIj7ONodCnQikf30Ddu
            sLXpsjfCijzdMH0pg5eMMbzbenlw8LA5yHp4Qf0ozTtAssdBQxHVxK9i1z4TMs6P
            8xsDo63utDD5A5Q27KMOxh2YIW8gbJ4uZz8t7qtqGVDl5m7DYihwUZ5i8za5y6mr
            cS5vxRklU3bewZot8Qt+unxnu5q2t1EgDDR4ZJNIOVPCvjhIeeLTSxt8Sos1nzsb
            zjYSjE+YCN6Cgp77baE1q5VXUBO1XF1XA9oBQDgqmcwj9ZUdo+MidtNHnQYyVmky
            knSZTcAKtXeW8LoGcsS9djuwJmFpWQXtZ7iJSWDqX2YpXYCMb+Hw4YjM8HvYJfgy
            Ox8FonhO0N4x51RnKAAekheZf+j+bMqZhtVm0OEtxNy+NOBu2oZGBoXDjLeHiMGC
            nK9N2Q+Ch0m//WBD70q4jB5RxL/8Y5Zm1cfIpvO7/hZVhJWzZqyWLhGVUBJOWNbO
            Q8GDmHfhjkgodOyJNEkrm5TxuRrS/2IuVYaZT6W/8z7bxDCA1G4e4C4xuBriptfz
            MorKbYeIdCrrYHVczljcUtHpBu4dfQHfFR3SsMnfWLqHO5uE0R29cGVhSgLItyMN
            3BUe1IDkfiYf6m7mhnM6s8ToERW7e7IR3GYpIzPvOMf4JZ+xBeiLe/HLxrbxiGgl
            1u+jU7SeZPnaYO28cFy8gUZbIJXpxDO8RJ8EXqeIKKUraIQPOjsjqQOilku1grT6
            NYxqfAMhcRZDlvkMhk+JIHwEvBh2yc28gmuTcL2vYu6C0AjL5/glT70HzwAEhiRx
            AjKO3XfyrKEmAsqo6dVWaBbPWMLlJHKRxqXN42dCd07+FWHo9D02BGURIIZbm7c4
            I6tJ8fThJug62t9Ug8kCVwp2k55dnzLrXn/cPClZE/Y6MIUzsd0SW7lzlefJtixs
            kUdnbK5tp2m1cakYJSb6O3+CPaHxN11Mpie633yH3NPryEeaTmoEfsLQybj7zZKC
            +o4XvvaeOa5j/jNfDpqAQ3eXL/QWzkzBW4R7GwfxtZbieXoNCPr2qqAEmbP+gbX3
            2fHdq2GTInEPTmRGVh8TkIVXU5KYdVQK6efqd1tCCW+xGKJacPzxiKosvljykieQ
            GQdEQNPVwmPRv4qznDpwZMra1pewJqtppsPdmbvNp4HaalO5nAdYglyQx/Q9nKfC
            NxPNxXpByh3pSznOievGhusnRWZwVsWh4iKdmm3O6SiFgzbfmSjNUvEZ2mIKXOFa
            v/0/ir4lK9KhwFSpQcT0WHbdwK+A5CvuGw8Mq409Ir+OlTpZ24QgVu4ALYstLZN3
            mNjV0fXxENP2ZRy0kqUmn0KoBA7BUCLu0I/dDNHXAshwcyYRQd1pdEsv8etNlmZQ
            vPASktc1FzE/wZQ+BRCUA6TGL41SG2hBVa0a5mcReOmtTs10jR3DXqF+1fVa/fSI
            G+6KZ/gzG+na2U+rdyXifYWedpVIR+VyM8+VeEKl1GDJQAzR6C/Q0SuFUFvf7hh3
            t1JPxx42lXi4USuO28prUkrkoIRWNvNxtmBobwP+A+7X1tNtOadSXoo=
            -----END ENCRYPTED PRIVATE KEY-----
            """,
        format: .pkcs8Encrypted,
        algorithm: .unknown,
        isEncrypted: true
    )

    static let ed25519PKCS8 = KeyFixture(
        name: "ed25519 PKCS#8 plain",
        text: """
            -----BEGIN PRIVATE KEY-----
            MC4CAQAwBQYDK2VwBCIEIGeqREI35uoovp3M9bKPKsLMTX8zp1MQu0sCYw6qw0RG
            -----END PRIVATE KEY-----
            """,
        format: .pkcs8,
        algorithm: .ed25519,
        isEncrypted: false,
        bitCount: 256,
        fingerprint: "SHA256:7pZ+5JAdhnF23h5wX8uT486BvE55wvSOMkSBEcZ72BU"
    )
}
