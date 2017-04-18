package io.github.olivierlemasle.ca;

import java.io.IOException;

import javax.security.auth.x500.X500Principal;

import org.bouncycastle.asn1.x500.X500Name;

class BcX500NameDnImpl implements DistinguishedName {
  private final X500Name x500Name;

  BcX500NameDnImpl(final X500Name name) {
    this.x500Name = name;
  }

  BcX500NameDnImpl(final String name) {
    this.x500Name = new X500Name(name);
  }
  
  BcX500NameDnImpl(final X500Principal principal) {
    this.x500Name = X500Name.getInstance(principal.getEncoded());
  }

  @Override
  public X500Name getX500Name() {
    return x500Name;
  }

  @Override
  public X500Principal getX500Principal() {
    try {
      return new X500Principal(x500Name.getEncoded());
    } catch (final IOException e) {
      throw new CaException(e);
    }
  }

  @Override
  public byte[] getEncoded() {
    try {
      return x500Name.getEncoded();
    } catch (final IOException e) {
      throw new CaException(e);
    }
  }

  @Override
  public String getName() {
    return x500Name.toString();
  }

  @Override
  public String toString() {
    return getName();
  }

}
